# -*- coding: utf-8 -*-
# Copyright: 2020, Diez B. Roggisch, Berlin . All rights reserved.
import laptimer.db as db


def setup_module():
    db.setup("sqlite://")


def test_setup():
    pilot = db.Pilot(name="deets")
    copter = db.Copter("hippo", pilot)
    db.session.add_all([pilot, copter])
    db.session.commit()


def test_master_data():
    assert(
        db.session.query(db.Channel).count() ==
        40
    )
    assert(db.CurrentState.instance())
