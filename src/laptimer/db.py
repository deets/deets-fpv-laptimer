# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
from sqlalchemy import Column
from sqlalchemy import create_engine
from sqlalchemy import ForeignKey
from sqlalchemy import Integer
from sqlalchemy import String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import backref
from sqlalchemy.orm import joinedload_all
from sqlalchemy.orm import relationship
from sqlalchemy.orm import Session
from sqlalchemy.orm.collections import attribute_mapped_collection


Base = declarative_base()

session = None  # needs setup to be called!


class Pilot(Base):

    __tablename__ = "pilots"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)


class Copter(Base):
    __tablename__ = "copter"

    id = Column(Integer, primary_key=True)
    name = Column(String(50), nullable=False)
    pilot_id = Column(Integer, ForeignKey("pilots.id"))

    pilot = relationship("Pilot")

    def __init__(self, name, pilot):
        self.name = name
        self.pilot = pilot

    def __repr__(self):
        return "Copter(name=%r, id=%r, pilot_id=%r)" % (
            self.name,
            self.id,
            self.pliot_id,
        )



def setup(uri, echo=False):
    global session
    engine = create_engine(uri, echo=echo)
    Base.metadata.create_all(engine)
    session = Session(engine)
