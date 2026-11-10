#!/usr/bin/env python3
"""Tests for autopromote's force_install_after_date handling.

Run from this directory: python3 -m unittest test_autopromote
"""

import os
import unittest

os.environ["CONFIG_FILE"] = os.path.join(os.path.dirname(__file__), "autopromote.json")

import arrow  # noqa: E402

import autopromote  # noqa: E402

DEADLINE_HOUR = 14
DEADLINE_MINUTE = 30


def at_deadline_time(days_from_now):
    """Naive wall-clock deadline days_from_now at the configured hour and minute."""
    day = arrow.now().shift(days=days_from_now).naive
    return day.replace(hour=DEADLINE_HOUR, minute=DEADLINE_MINUTE, second=0, microsecond=0)


def deadline_of(result):
    """The promoted plist's deadline to the minute; stamping keeps the seconds of now."""
    deadline = arrow.get(result["plist"]["force_install_after_date"]).naive
    return deadline.replace(second=0, microsecond=0)


def pkginfo(version, catalogs, deadline=None):
    plist = {
        "name": "GoogleChrome",
        "version": version,
        "catalogs": list(catalogs),
        "_metadata": {"last_promoted": arrow.now().shift(days=-30).naive},
    }
    if deadline is not None:
        plist["force_install_after_date"] = deadline
    return plist


class CarryForwardTest(unittest.TestCase):
    def setUp(self):
        self.saved_config = dict(autopromote.CONFIG)
        autopromote.CONFIG.update(
            {
                "enforce_force_install_date": True,
                "enforce_force_install_time": True,
                "force_install_time": {"hour": DEADLINE_HOUR, "minute": DEADLINE_MINUTE},
                "patch_tuesday": None,
                "force_install_allowlist": [],
                "force_install_denylist": [],
                "force_install_carry_forward": True,
            }
        )
        autopromote.PKGINFOS_PATHS = []

    def tearDown(self):
        autopromote.CONFIG.clear()
        autopromote.CONFIG.update(self.saved_config)
        autopromote.PKGINFOS_PATHS = []

    def promote_into_prerelease(self, *others):
        """Promotes 2.0 from canary into prerelease (9 force-install days) and
        returns its deadline."""
        new = pkginfo("2.0", ["import", "canary"])
        autopromote.PKGINFOS_PATHS = [(new, "new.plist")]
        autopromote.PKGINFOS_PATHS += [(p, f"other{i}.plist") for i, p in enumerate(others)]
        promoted, result = autopromote.promote_pkg(new, "new.plist")
        self.assertTrue(promoted)
        self.assertEqual(result["to"], "prerelease")
        return deadline_of(result)

    def test_off_by_default_keeps_fresh_deadline(self):
        del autopromote.CONFIG["force_install_carry_forward"]
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(older), at_deadline_time(9))

    def test_carries_earlier_unexpired_deadline(self):
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(older), at_deadline_time(3))

    def test_ignores_expired_deadline(self):
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(-1))
        self.assertEqual(self.promote_into_prerelease(older), at_deadline_time(9))

    def test_never_moves_deadline_later(self):
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(20))
        self.assertEqual(self.promote_into_prerelease(older), at_deadline_time(9))

    def test_ignores_versions_not_in_target_catalog(self):
        older = pkginfo("1.0", ["import", "canary"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(older), at_deadline_time(9))

    def test_uses_only_newest_older_version(self):
        newest_older = pkginfo("1.5", ["import", "canary", "prerelease"])
        oldest = pkginfo("1.0", ["import", "canary", "prerelease", "release"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(newest_older, oldest), at_deadline_time(9))

    def test_takes_earliest_deadline_across_builds_of_one_version(self):
        arm = pkginfo("1.0", ["import", "canary", "prerelease"])
        intel = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(4))
        universal = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(2))
        self.assertEqual(self.promote_into_prerelease(arm, intel, universal), at_deadline_time(2))

    def test_unparseable_version_turns_carry_off(self):
        broken = pkginfo("not a version", ["import", "canary", "prerelease"])
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(broken, older), at_deadline_time(9))

    def test_unparseable_promoted_version_keeps_fresh_deadline(self):
        new = pkginfo("2.0 beta build", ["import", "canary"])
        older = pkginfo("1.0", ["import", "canary", "prerelease"], at_deadline_time(3))
        autopromote.PKGINFOS_PATHS = [(new, "new.plist"), (older, "old.plist")]
        promoted, result = autopromote.promote_pkg(new, "new.plist")
        self.assertTrue(promoted)
        self.assertEqual(deadline_of(result), at_deadline_time(9))

    def test_ignores_newer_versions(self):
        newer = pkginfo("3.0", ["import", "canary", "prerelease"], at_deadline_time(3))
        self.assertEqual(self.promote_into_prerelease(newer), at_deadline_time(9))


if __name__ == "__main__":
    unittest.main()
