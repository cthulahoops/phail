import sys
import pathlib

import psycopg2

from message import Message

from config_secret import (host, user, password, database)

dbh = psycopg2.connect(host=host, user=user, password=password, database=database)

def create_address(address):
    cursor = dbh.cursor()
    cursor.execute("insert into addresses (name, address) values (%s, %s) returning (id)", (
        address['name'],
        address['email']))
    address = cursor.fetchone()
    return address

def get_address(address):
    cursor = dbh.cursor()
    cursor.execute("select id from addresses where name = %s and address = %s", (
        address['name'],
        address['email']))
    return (cursor.fetchone() or create_address(address))[0]

def insert_conversation_from(conversation_id, address_id):
    table_name = f"conversation_from_address"
    sql = f"insert into {table_name} (conversation_id, address_id) values (%s, %s) on conflict do nothing"
    cursor = dbh.cursor()
    cursor.execute(sql, (conversation_id, address_id))

def insert_assoc(assoc_type, message_id, address_id):
    table_name = f"message_{assoc_type}_address"
    sql = f"insert into {table_name} (message_id, address_id) values (%s, %s) on conflict do nothing"
    cursor = dbh.cursor()
    cursor.execute(sql, (message_id, address_id))

def insert_reference(message_id, reference):
    with dbh.cursor() as cursor:
        cursor.execute(
            "insert into message_references (message_id, reference) values (%s, %s) on conflict do nothing", (
                message_id,
                reference))

def get_referenced_conversation(message):
    with dbh.cursor() as cursor:
        cursor.execute("""select distinct messages.conversation_id
            from messages
            join message_references on messages.message_id = message_references.reference
            join messages myself on myself.id = message_references.message_id
            where myself.message_id = %s""", (message.message_id,))
        conversation_ids = cursor.fetchall()
        if len(conversation_ids) > 1:
            print(conversation_ids)
        if conversation_ids:
            return conversation_ids[0]

def get_referencing_conversation(message):
    with dbh.cursor() as cursor:
        cursor.execute("""select distinct messages.conversation_id
            from messages
            join message_references on messages.id = message_references.message_id
            where message_references.reference = %s""", (message.message_id,))
        conversation_ids = cursor.fetchall()
        if len(conversation_ids) > 1:
            print(conversation_ids)
        if conversation_ids:
            return conversation_ids[0]

def get_new_conversation(message):
    with dbh.cursor() as cursor:
        cursor.execute("insert into conversations (subject) values (%s) returning (id)", (message.subject,))
        return cursor.fetchone()

def get_conversation(message):
    return (
        get_referenced_conversation(message)
        or get_referencing_conversation(message)
        or get_new_conversation(message))

def insert_message(message):
    from_addresses = list(map(get_address, message.addresses('from')))
    to_addresses = list(map(get_address, message.addresses('to')))
    cc_addresses = list(map(get_address, message.addresses('cc')))

    cursor = dbh.cursor()
    cursor.execute("insert into messages (subject, body, message_id, date) values (%s, %s, %s, %s) returning (id)", (
        message.subject,
        message.body,
        message.message_id,
        message.date,))
    message_id = cursor.fetchone()[0]

    for address_id in from_addresses:
        insert_assoc("from", message_id, address_id)

    for address_id in to_addresses:
        insert_assoc("to", message_id, address_id)

    for address_id in cc_addresses:
        insert_assoc("cc", message_id, address_id)

    for reference in message.references:
        insert_reference(message_id, reference)

    dbh.commit()

    conversation_id = get_conversation(message)
    with dbh.cursor() as cursor:
        cursor.execute("update messages set conversation_id = %s where id = %s",
            (conversation_id, message_id))

    for address_id in from_addresses:
        insert_conversation_from(conversation_id, address_id)


def main():
    for item in pathlib.Path(sys.argv[1]).iterdir():
        try:
            message = Message(open(item, mode='rb'))
            insert_message(message)
        except:
            print("Failed to load: ", item)
            raise

if __name__ == '__main__':
    main()
