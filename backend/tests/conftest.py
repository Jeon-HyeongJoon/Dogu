import os

import pytest

from app.config import get_settings


@pytest.fixture(autouse=True, scope="session")
def _isolate_state(tmp_path_factory) -> None:
    """Route writable state (orders DB, seed override) to a throwaway dir so
    tests never touch real state or each other's."""
    os.environ["DOGU_STATE_DIR"] = str(tmp_path_factory.mktemp("dogu-state"))
    get_settings.cache_clear()
