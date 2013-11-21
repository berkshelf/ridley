# 2.0.0

* [#227](https://github.com/RiotGames/ridley/pull/227) HostCommander and HostConnector code has been moved into its own gem - [found here](https://github.com/RiotGames/ridley-connectors)
  * As discussed by @jtimberman in [#225](https://github.com/RiotGames/ridley/issues/225) it makes sense to move this code based on Ridley's main purpose, and gives a decent performance boost to users who don't need this extra functionality.

# 1.7.1

* [#224](https://github.com/RiotGames/ridley/pull/224) Connection#stream will now return true/false on whether it copied the file that was streamed.
