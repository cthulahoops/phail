import sys
import pathlib
import mailbox
import argparse

import psycopg2

from message import Message

from config_secret import host, user, password, database

dbh = psycopg2.connect(host=host, user=user, password=password, database=database)

ignore_labels = ("opened", "unread", "archived", "sent")


def create_address(address):
    cursor = dbh.cursor()
    cursor.execute(
        "insert into addresses (name, address) values (%s, %s) returning (id)",
        (address["name"], address["email"]),
    )
    address = cursor.fetchone()
    return address


def get_address(address):
    cursor = dbh.cursor()
    cursor.execute(
        "select id from addresses where name = %s and address = %s",
        (address["name"], address["email"]),
    )
    return (cursor.fetchone() or create_address(address))[0]


def insert_message_address(address_type, message_id, address):
    sql = """insert into message_addresses
        (message_id, type, address, name)
        values (%s, %s, %s, %s) on conflict do nothing"""
    cursor = dbh.cursor()
    cursor.execute(sql, (message_id, address_type, address["email"], address["name"]))


def create_label(name):
    cursor = dbh.cursor()
    cursor.execute("insert into labels (name) values (%s) returning (id)", (name,))
    return cursor.fetchone()[0]


def get_label(name):
    cursor = dbh.cursor()
    cursor.execute("select id from labels where name = %s", (name,))
    return cursor.fetchone() or create_label(name)


def insert_label_assoc(conversation_id, label_name):
    label_id = get_label(label_name)
    cursor = dbh.cursor()
    cursor.execute(
        "insert into conversation_labels (conversation_id, label_id) values (%s, %s) on conflict do nothing",
        (conversation_id, label_id),
    )


def insert_reference(message_id, reference):
    with dbh.cursor() as cursor:
        cursor.execute(
            "insert into message_references (message_id, reference) values (%s, %s) on conflict do nothing",
            (message_id, reference),
        )


def get_referenced_conversations(message):
    with dbh.cursor() as cursor:
        cursor.execute(
            """select distinct messages.conversation_id
            from messages
            join message_references on messages.message_id = message_references.reference
            join messages myself on myself.id = message_references.message_id
            where myself.message_id = %s""",
            (message.message_id,),
        )
        return list(cursor.fetchall())


def get_referencing_conversations(message):
    with dbh.cursor() as cursor:
        cursor.execute(
            """select distinct messages.conversation_id
            from messages
            join message_references on messages.id = message_references.message_id
            where message_references.reference = %s""",
            (message.message_id,),
        )
        return list(cursor.fetchall())


def get_new_conversation(message):
    with dbh.cursor() as cursor:
        cursor.execute(
            "insert into conversations (subject) values (%s) returning (id)",
            (message.subject,),
        )
        return cursor.fetchone()[0]


def merge_conversations(conversation_ids):
    if not conversation_ids:
        return None
    if len(conversation_ids) == 1:
        return conversation_ids[0][0]

    conversation_ids = tuple([id for (id,) in conversation_ids])
    with dbh.cursor() as cursor:
        cursor.execute(
            """select conversations.id from conversations
                join messages on messages.conversation_id = conversations.id
                where conversations.id in %s group by 1
                order by min(messages.date) limit 1""",
            (conversation_ids,),
        )

        (earliest_conversation_id,) = cursor.fetchone()
        print("Earliest reference: ", earliest_conversation_id)

        conversation_ids = tuple(
            [x for x in conversation_ids if x != earliest_conversation_id]
        )
        cursor.execute(
            """update messages
                set conversation_id = %(earliest_conversation_id)s
                where conversation_id in %(conversation_ids)s""",
            {
                "earliest_conversation_id": earliest_conversation_id,
                "conversation_ids": conversation_ids,
            },
        )

        cursor.execute("delete from conversations where id in %s", (conversation_ids,))

    return earliest_conversation_id


def get_conversation(message):
    return merge_conversations(
        get_referenced_conversations(message) + get_referencing_conversations(message)
    ) or get_new_conversation(message)


def insert_message(message, extra_labels=()):
    if "Chat" in message.labels:
        return  # Skip chats for now!

    cursor = dbh.cursor()
    cursor.execute(
        "insert into messages (subject, body, message_id, date) values (%s, %s, %s, %s) returning (id)",
        (message.subject, message.body, message.message_id, message.date,),
    )
    message_id = cursor.fetchone()[0]

    for address_type in ["from", "to", "cc"]:
        for address in message.addresses(address_type):
            insert_message_address(address_type, message_id, address)

    for reference in message.references:
        insert_reference(message_id, reference)

    conversation_id = get_conversation(message)
    with dbh.cursor() as cursor:
        cursor.execute(
            "update messages set conversation_id = %s where id = %s",
            (conversation_id, message_id),
        )

    for label in message.labels + list(extra_labels):
        if label.lower() in ignore_labels:
            continue
        insert_label_assoc(conversation_id, label)

    dbh.commit()


def iter_dir_messages(directory_name):
    for item in pathlib.Path(directory_name).iterdir():
        yield Message(open(item, mode="rb").read())


def iter_file_messages(filename):
    mbox = mailbox.mbox(filename)

    for message in mbox:
        yield Message(message.as_bytes())


def read_message_from_stdin():
    return Message(sys.stdin.buffer.read())


def load_messages_from_file_or_directory(input_filename):
    i = 0
    for message in iter_file_messages(input_filename):
        try:
            insert_message(message)
        except:
            print("Failed to load: ", message)
            raise
        if i % 100 == 0:
            print(i)
        i += 1


def main():
    parser = argparse.ArgumentParser("Load mail into phail")
    parser.add_argument(
        "-c", "--stdin", action="store_true", help="Read a message from stdin."
    )
    parser.add_argument(
        "-l", "--label", help="Apply label to message", action="append", default=[]
    )
    parser.add_argument("paths", nargs="*", help="Paths to mbox or maildir input")
    args = parser.parse_args()

    if args.stdin:
        message = read_message_from_stdin()
        insert_message(message, extra_labels=args.label)

    for path in args.paths:
        load_messages_from_file_or_directory(path)


if __name__ == "__main__":
    main()
