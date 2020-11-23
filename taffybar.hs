{-# LANGUAGE OverloadedStrings #-}
import System.Taffybar
import System.Taffybar.Information.CPU
import System.Taffybar.Information.Memory
import System.Taffybar.SimpleConfig
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.Graph
import System.Taffybar.Widget.Generic.PollingGraph

import Data.Maybe
import Text.Read
import System.Environment

cpuCallback :: IO [Double]
cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [ totalLoad, systemLoad ]

memCallback :: IO [Double]
memCallback = do
  mem <- parseMeminfo
  return [memoryUsedRatio mem]




main = do
  monitorStr <- getEnv "TAFFYBAR_MONITOR"
  let cpuGraphConfig = defaultGraphConfig { graphDataColors = [ (0, 1, 0, 1), (1, 0, 1, 0.5) ]
                                          , graphLabel = Just "CPU:"
                                          }
      memGraphConfig = defaultGraphConfig { graphDataColors = [ (0, 1, 0, 1), (1, 0, 1, 0.5) ]
                                          , graphLabel = Just "Memory:"
                                          }
  let cpu = pollingGraphNew cpuGraphConfig 0.5 cpuCallback
      mem = pollingGraphNew memGraphConfig 0.5 memCallback
      clock = textClockNewWith defaultClockConfig
      alerts = notifyAreaNew defaultNotificationConfig
      net = networkMonitorNew defaultNetFormat $ Just ["wlp4s0"]
      music = mpris2New
      tray = sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt
      
      workspaces =  workspacesNew defaultWorkspacesConfig
      rightConfig = defaultSimpleTaffyConfig
                    { startWidgets = [
                        tray,
                        music
                        ]
                    , centerWidgets = [
                        workspaces
                        ]
                    , endWidgets = [
                        alerts,
                        mem,
                        cpu,
                        net
                        ]
                    , barPosition = Top
                    , monitorsAction = pure [1]
                    }
      leftConfig = defaultSimpleTaffyConfig
                   { centerWidgets = [ workspaces ]
                   , endWidgets = [ clock ]
                   , barPosition = Top
                   , monitorsAction = pure [0]
                   }
      monitor = fromMaybe 0 $ readMaybe $ monitorStr
      config = case monitor of
        0 -> leftConfig
        1 -> rightConfig
        _ -> leftConfig

        
  simpleTaffybar config
