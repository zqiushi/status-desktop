import allure
import pytest
import logging

from driver.server import SquishServer

LOG = logging.getLogger(__name__)


@pytest.fixture(scope='session')
def start_squish_server():
    server = SquishServer()
    server.stop()
    try:
        server.start()
        server.wait()
        yield server
    except Exception as err:
        LOG.error('Failed to start Squish Server: %s', error)
        pytest.exit(err)
    finally:
        LOG.info('Stopping Squish Server...')
        server.stop()
    if server.config.exists():
        allure.attach.file(str(server.config), 'Squish server config')
        server.config.unlink()
