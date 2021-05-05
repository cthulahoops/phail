import email
import email.utils
import email.header
import email.policy
import datetime
import pytz
import base64
import quopri
import bleach

CHARSET_ALIASES = {
    "iso: western": "latin1",
    "x-unknown": "latin1",
    "unknown-8bit": "latin1",
    "windows-874": "cp874",
    "default": "utf-8",
    "": "utf-8",
}


def decode_header(header):
    return "".join(
        decode_charset(part, encoding)
        for (part, encoding) in email.header.decode_header(header)
    )

class SimpleTz(datetime.tzinfo):
    def __init__(self, offset):
        self.offset = offset

    def utcoffset(self, dt):
        return datetime.timedelta(0, self.offset, 0)


def parse_date(datestr):
    date = email.utils.parsedate_tz(datestr)
    tz = SimpleTz(date[-1] or 0)
    date = date[:7] + (tz,)
    return datetime.datetime(*date).astimezone(pytz.utc)


class Message:
    def __init__(self, text, filename=None):
        # if not filename:
        #     filename = fh.name
        self.text = text
        self.filename = filename
        self.mail = email.message_from_bytes(self.text, policy=email.policy.default)

    @property
    def message_id(self):
        return self.mail.get("message-id").strip()

    @property
    def subject(self):
        return decode_header(self.mail.get("subject", ""))

    @property
    def is_unread(self):
        return "/new/" in self.filename

    @property
    def date(self):
        datestr = self.mail.get("date")
        if not datestr:
            received = self.mail.get("Received")
            if not received:
                return None
            return parse_date(received.split(";")[-1])
        return parse_date(datestr)

    def addresses(self, address_type):
        headers = self.mail.get_all(address_type)
        if headers:
            return [
                {"name": decode_header(name), "email": address}
                for (name, address) in email.utils.getaddresses(map(str, headers))
            ]
        return []

    @property
    def labels(self):
        labels = self.mail.get('X-Gmail-Labels')
        if labels:
            return labels.split(',')
        return []

    @property
    def references(self):
        references = self.mail.get("references")
        if references:
            return [x.strip() for x in references.split()]
        return []

    @property
    def body(self):
        return content(self.mail)

    def document(self):
        try:
            return {
                "from": self.addresses("from"),
                "to": self.addresses("to"),
                "cc": self.addresses("cc"),
                "subject": self.subject,
                "message_id": self.message_id,
                "date": self.date.isoformat(),
                "filename": self.filename,
                "unread": self.is_unread,
                "body": self.body(),
                # 		'original': base64.b64encode(message.text)
            }
        except:
            print("Failure loading %r" % (self.filename,))
            raise

    @property
    def attachments(self):
        yield from self.mail.iter_attachments()

def htmlify(text):
    return text.replace(">", "&gt;").replace("<", "&lt;").replace("\n", "<br/>")


def decode(mail):
    text = mail.get_payload(decode=True)
    character_encoding = mail.get_charsets()[0]
    return decode_charset(text, character_encoding)


def decode_charset(text, charset):
    if isinstance(text, str):
        return text
    if charset is None:
        return text.decode(errors='replace')
    charset = charset.lower().strip()
    charset = CHARSET_ALIASES.get(charset, charset)
    return text.decode(encoding=charset, errors="ignore")


def decode_transfer(text, encoding):
    if encoding:
        encoding = encoding.lower().strip()

    if encoding == "quoted-printable":
        return quopri.decodestring(text)
    if encoding == "base64":
        return base64.b64decode(text)
    if encoding in (None, "7bit", "8bit", "binary"):
        return text
    raise ValueError("Unsupported transfer encoding: %r" % (encoding,))


alternative_order = {"text/plain": 1, "text/html": 2}


def content(mail):
    content_type = mail.get_content_type()
    if content_type in ("multipart/mixed", "multipart/related"):
        for part in mail.get_payload():
            disposition = part.get("Content-Disposition")
            if disposition and (
                disposition.startswith("attachment") or disposition.startswith("inline")
            ):
                continue
            return content(part)
        return ""
    if content_type in (
        "multipart/alternative",
        "multipart/signed",
        "multipart/report",
    ):
        preferred = max(
            mail.get_payload(),
            key=lambda m: alternative_order.get(m.get_content_type(), 0),
        )
        return content(preferred)
    if content_type == "text/plain":
        return htmlify(decode(mail))
    if content_type == "text/html":
        html = decode(mail)
        return bleach.clean(
            html,
            tags=[
                "a",
                "abbr",
                "acronym",
                "b",
                "blockquote",
                "code",
                "em",
                "i",
                "li",
                "ol",
                "strong",
                "ul",
                "p",
                "br",
                "div",
                "span",
                "body",
                "h1",
                "h2",
                "h3",
                "table",
                "td",
                "tr",
                "tbody",
                "thead",
                "img",
                "u",
                "pre",
            ],
            attributes={
                "a": ["href", "title"],
                "abbr": ["title"],
                "acronym": ["title"],
                "img": ["alt"],
                "*": ["style"],
            },
            styles=["color", "font-family", "background-color", "font-size"],
        )
    raise ValueError("Unsupported: %r" % (content_type,))
