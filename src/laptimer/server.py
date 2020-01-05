import argparse

import tornado.ioloop
import tornado.web

from .db import setup


class MainHandler(tornado.web.RequestHandler):
    def get(self):
        self.write("Hello, world")


def make_app():
    return tornado.web.Application([
        (r"/", MainHandler),
    ])


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--port",
        type=int,
        default=8888,
    )
    parser.add_argument(
        "--db",
        required=True,
        help="SQLAlchemy database URI. "
        "E.g. sqlite:////tmp/laptimer.db "
        "for a sqlite db given as full path."
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    setup(args.db, echo=args.verbose)
    app = make_app()
    app.listen(args.port)
    tornado.ioloop.IOLoop.current().start()
