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


def insert_message_address(user_id, address_type, message_id, address):
    sql = """insert into message_addresses
        (user_id, message_id, type, address, name)
        values (%s, %s, %s, %s, %s) on conflict do nothing"""
    cursor = dbh.cursor()
    cursor.execute(
        sql, (user_id, message_id, address_type, address["email"], address["name"])
    )


def create_label(user_id, name):
    cursor = dbh.cursor()
    cursor.execute(
        "insert into labels (user_id, name) values (%s, %s) returning (id)",
        (user_id, name,),
    )
    return cursor.fetchone()[0]


def get_label(user_id, name):
    cursor = dbh.cursor()
    cursor.execute(
        "select id from labels where name = %s and user_id = %s", (name, user_id)
    )
    return cursor.fetchone() or create_label(user_id, name)


def insert_label_assoc(user_id, conversation_id, label_name):
    label_id = get_label(user_id, label_name)
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


def get_referenced_conversations(user_id, message):
    if not message.references:
        return []

    with dbh.cursor() as cursor:
        cursor.execute(
            """select distinct messages.conversation_id
            from messages
            where message_id in %s and user_id = %s""",
            (tuple(message.references), user_id),
        )
        return list(cursor.fetchall())


def get_referencing_conversations(user_id, message):
    with dbh.cursor() as cursor:
        cursor.execute(
            """select distinct messages.conversation_id
            from messages
            join message_references on messages.id = message_references.message_id
            where message_references.reference = %s and user_id = %s""",
            (message.message_id, user_id),
        )
        return list(cursor.fetchall())


def get_new_conversation(user_id, message):
    with dbh.cursor() as cursor:
        cursor.execute(
            "insert into conversations (user_id, subject) values (%s, %s) returning (id)",
            (user_id, message.subject,),
        )
        return cursor.fetchone()[0]


def get_mutual_references(user_id, message):
    references = tuple(message.references)
    if not references:
        return []

    with dbh.cursor() as cursor:
        print("References: ", references)
        cursor.execute(
            """select distinct conversation_id from messages
                join message_references on messages.id = message_references.message_id
                where reference in %s and user_id = %s""",
            (references, user_id),
        )
        return list(cursor.fetchall())


def merge_conversations(conversation_ids):
    conversation_ids = tuple(set(id for (id,) in conversation_ids))
    print("Merging: ", conversation_ids)
    if not conversation_ids:
        return None
    if len(conversation_ids) == 1:
        return conversation_ids[0]

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


def get_conversation(user_id, message):
    return merge_conversations(
        get_referenced_conversations(user_id, message)
        + get_referencing_conversations(user_id, message)
        + get_mutual_references(user_id, message)
    ) or get_new_conversation(user_id, message)


def insert_message(user_id, message, extra_labels=()):
    if "Chat" in message.labels:
        return  # Skip chats for now!

    conversation_id = get_conversation(user_id, message)

    cursor = dbh.cursor()
    cursor.execute(
        """insert into messages (user_id, conversation_id, subject, body, message_id, date)
            values (%s, %s, %s, %s, %s, %s)
            returning (id)""",
        (
            user_id,
            conversation_id,
            message.subject,
            message.body,
            message.message_id,
            message.date,
        ),
    )
    message_id = cursor.fetchone()[0]

    for address_type in ["from", "to", "cc"]:
        for address in message.addresses(address_type):
            insert_message_address(user_id, address_type, message_id, address)

    for reference in message.references:
        insert_reference(message_id, reference)

    for label in message.labels + list(extra_labels):
        if label.lower() in ignore_labels:
            continue
        insert_label_assoc(user_id, conversation_id, label)

    cursor.execute(
        "insert into originals (user_id, message_id, text) values (%(user_id)s, %(message_id)s, %(text)s)",
        dict(user_id=user_id, message_id=message_id, text=message.text),
    )

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


def load_messages_from_file_or_directory(user_id, input_filename):
    i = 0
    for message in iter_file_messages(input_filename):
        try:
            insert_message(user_id, message)
        except:
            print("Failed to load: ", message)
            raise
        if i % 100 == 0:
            print(i)
        i += 1


def get_user_id(recipient):
    with dbh.cursor() as cursor:
        cursor.execute("select id from users where email = %s", (recipient,))
        row = cursor.fetchone()
    if row:
        (user_id,) = row
        return user_id
    return None


def main():
    parser = argparse.ArgumentParser("Load mail into phail")
    parser.add_argument("recipient")
    parser.add_argument(
        "-c", "--stdin", action="store_true", help="Read a message from stdin."
    )
    parser.add_argument(
        "-l", "--label", help="Apply label to message", action="append", default=[]
    )
    parser.add_argument("paths", nargs="*", help="Paths to mbox or maildir input")
    args = parser.parse_args()

    user_id = get_user_id(args.recipient)

    if not user_id:
        print(f"User does not exist: {args.recipient}")
        sys.exit(1)

    if args.stdin:
        message = read_message_from_stdin()
        insert_message(user_id, message, extra_labels=args.label)

    for path in args.paths:
        load_messages_from_file_or_directory(user_id, path)


if __name__ == "__main__":
    main()
