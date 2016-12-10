#!/usr/bin/env python
"""
 * synnova.py
 *
 *  Copyright Synerty Pty Ltd 2013
 *
 *  This software is proprietary, you are not free to copy
 *  or redistribute this code in any format.
 *
 *  All rights to this software are reserved by
 *  Synerty Pty Ltd
 *
"""
from txhttputil.util import LoggingUtil

LoggingUtil.setup()

from twisted.internet import reactor

from txhttputil import RapuiConfig
from txhttputil import printFailure
from txhttputil import DirSettings

RapuiConfig.enabledJsRequire = False

import logging

# EXAMPLE LOGGING CONFIG
# Hide messages from vortex
# logging.getLogger('txhttputil.vortex.VortexClient').setLevel(logging.INFO)

# logging.getLogger('peek_agent_pof.realtime.RealtimePollerEcomProtocol'
#                   ).setLevel(logging.INFO)

logger = logging.getLogger(__name__)

# ------------------------------------------------------------------------------
# Set the parallelism of the database and reactor
reactor.suggestThreadPoolSize(10)


def main():
    # defer.setDebugging(True)
    # sys.argv.remove(DEBUG_ARG)
    # import pydevd
    # pydevd.settrace(suspend=False)


    from peek_platform import PeekPlatformConfig
    PeekPlatformConfig.componentName = "peek_agent"

    # Tell the platform classes about our instance of the PappSwInstallManager
    from peek_agent.sw_install.PappSwInstallManager import pappSwInstallManager
    PeekPlatformConfig.pappSwInstallManager = pappSwInstallManager

    # Tell the platform classes about our instance of the PeekSwInstallManager
    from peek_agent.sw_install.PeekSwInstallManager import peekSwInstallManager
    PeekPlatformConfig.peekSwInstallManager = peekSwInstallManager

    # Tell the platform classes about our instance of the PeekLoaderBase
    from peek_agent.papp.PappAgentLoader import pappAgentLoader
    PeekPlatformConfig.pappLoader = pappAgentLoader

    # The config depends on the componentName, order is important
    from peek_agent.PeekAgentConfig import peekAgentConfig
    PeekPlatformConfig.config = peekAgentConfig

    # Set default logging level
    logging.root.setLevel(peekAgentConfig.loggingLevel)

    # Initialise the txhttputil Directory object
    DirSettings.defaultDirChmod = peekAgentConfig.DEFAULT_DIR_CHMOD
    DirSettings.tmpDirPath = peekAgentConfig.tmpPath

    # Load server restart handler handler
    from peek_platform import PeekServerRestartWatchHandler
    PeekServerRestartWatchHandler.__unused = False

    # First, setup the Vortex Agent
    from peek_platform import peekVortexClient
    d = peekVortexClient.connect()
    d.addErrback(printFailure)

    # Start Update Handler,
    from peek_platform import peekSwVersionPollHandler
    # Add both, The peek client might fail to connect, and if it does, the payload
    # sent from the peekSwUpdater will be queued and sent when it does connect.
    d.addBoth(lambda _: peekSwVersionPollHandler.start())


    # Load all Papps
    from peek_agent.papp.PappAgentLoader import pappAgentLoader
    d.addBoth(lambda _ : pappAgentLoader.loadAllPapps())

    d.addErrback(printFailure)

    # Init the realtime handler

    logger.info('Peek Agent is running, version=%s', peekAgentConfig.platformVersion)
    reactor.run()


if __name__ == '__main__':
    main()