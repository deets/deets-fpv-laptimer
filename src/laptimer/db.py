# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
from sqlalchemy import (
    create_engine,
    Column,
    ForeignKey,
    Integer,
    String,
    PrimaryKeyConstraint,
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.orm import Session

from .common import CHANNELS

Base = declarative_base()

session = None  # needs setup to be called!


class Channel(Base):
    __tablename__ = "channels"

    id = Column(Integer, primary_key=True)
    frequency = Column(Integer, nullable=False)
    name = Column(String, nullable=False)


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


class Heat(Base):

    __tablename__ = "heats"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)

    @classmethod
    def active(cls):
        return CurrentState.instance().heat


class HeatEntry(Base):

    __tablename__ = "heat_entries"

    heat_id = Column(Integer, ForeignKey("heats.id"), primary_key=True)
    copter_id = Column(Integer, ForeignKey("copter.id"), primary_key=True)
    channel_id = Column(Integer, ForeignKey("channels.id"), primary_key=True)

    heat = relationship("Heat")
    channel = relationship("Channel")
    copter = relationship("Copter")


class CurrentState(Base):

    __tablename__ = "current_state"

    id = Column(Integer, primary_key=True)
    heat_id = Column(Integer, ForeignKey("heats.id"))

    heat = relationship("Heat")

    @classmethod
    def instance(cls):
        return session.query(cls).first()


def create_master_data():
    for band, frequencies in CHANNELS.items():
        for index, frequency in enumerate(frequencies, start=1):
            name = f"{band}{index}"
            existing = session.query(Channel).\
                filter(Channel.name == name).\
                filter(Channel.frequency == frequency).first()
            if existing is None:
                channel = Channel()
                channel.frequency = frequency
                channel.name = name
                session.add(channel)

    cs_count = session.query(CurrentState).count()
    assert cs_count <= 1, "Too many CurrentState entries!"
    if not cs_count:
        cs = CurrentState()
        cs.id = 1
        session.add(cs)
    session.commit()


def setup(uri, *, echo=False):
    global session
    engine = create_engine(uri, echo=echo)
    Base.metadata.create_all(engine)
    session = Session(engine)
    create_master_data()
