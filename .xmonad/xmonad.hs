import XMonad hiding ((|||))
import XMonad.Actions.WindowNavigation
import XMonad.Config.Desktop
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Accordion
import XMonad.Layout.Combo
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.Renamed
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.StackTile
import XMonad.Layout.TwoPane
import XMonad.Prompt
import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run(spawnPipe)

import qualified XMonad.StackSet as W

import System.IO

myLayout = desktopLayoutModifiers $
    onWorkspace "2:im/mail"  (Accordion ||| Full) $
    onWorkspace "3:media" Full $
    onWorkspace "4:vm" Full $
    accordionTwoPane ||| tiled ||| stackTwo ||| Full
  where
    accordionTwoPane = renamed [Replace "Accordion/TwoPane"] (
        combineTwo (TwoPane (3/100) (1/2)) (Accordion) (Full))
    stackTwo = renamed [Replace "StackTwo"] (
        combineTwo (StackTile 1 (3/100) (1/2)) (Full) (Full))
    tiled = renamed [Replace "Tiled"] (reflectHoriz $ Tall 1 (3/100) (1/2))

myManageHook = composeAll [
    -- some dialog windows that don't float by default
    className =? "Keyring"            --> doFloat,
    className =? "Zenity"             --> doFloat,
    -- gimp insists on floating, so prevent that.
    role =? "gimp-image-window"       --> ask >>= doF . W.sink
  ]
  where
    role = stringProperty "WM_WINDOW_ROLE"

myTerminal = "alacritty"
myWorkspaces = ["1:main", "2:im/mail", "3:media", "4:vm"]
myScratchpads = [
    NS "scratchterm"
      "alacritty --class scratchterm -e tmux -L scratch new-session -s scratch -A"
      (className =? "scratchterm")
      (customFloating $ W.RationalRect l t w h)
  ]
  where
    h = 0.2    -- height, 20%
    w = 1      -- width, 100%
    t = 1 - h  -- distance from top edge (bottom, based on height)
    l = 0      -- distance from left edge

noScratchPad ws = if ws == "NSP" then "" else ws

-- 4k monitor
barFont = "Terminus 14"
-- 1080p
--barFont = "Terminus 9"
barBackground = "#232323"
barForeground = "#aaaaaa"

main = do
  workspaceBar <- spawnPipe (
    "xmobar " ++
      "-p 'TopH 25' " ++
      "-f '" ++ barFont ++ "' " ++
      "-B '" ++ barBackground ++ "' " ++
      "-F '" ++ barForeground ++ "'")
  spawn "xset -b"
  spawn "xset r rate 250 30"
  spawn "xsetroot -cursor_name left_ptr"
  spawn "hsetroot -solid '#333333'"
  spawn "xmodmap ~/.Xmodmap"
  spawn ("pkill conky ; conky -c ~/.dzen/conkyrc | ~/bin/dzen2 " ++
    "-xp 40 " ++
    "-wp 60 " ++
    "-fn '" ++ barFont ++ "' " ++
    "-bg '" ++ barBackground ++ "' " ++
    "-fg '" ++ barForeground ++ "' " ++
    "-ta r &")
  spawn "pkill keynav ; keynav &"
  spawn "pkill xcompmgr ; xcompmgr -c -r0 &"
  spawn "pkill -9 unclutter ; sleep 0.3 ; unclutter --timeout 2 &"
  config <-
    withWindowNavigation(xK_k, xK_h, xK_j, xK_l) $
    ewmh $ desktopConfig {
      borderWidth        = 1,
      modMask            = mod1Mask,
      terminal           = myTerminal,
      normalBorderColor  = "#333333",
      focusedBorderColor = "#5884b0",
      workspaces         = myWorkspaces,
      manageHook         =
        manageDocks <+>
        myManageHook <+>
        manageHook desktopConfig <+>
        namedScratchpadManageHook myScratchpads,
      layoutHook         = myLayout,
      focusFollowsMouse  = False,
      logHook            = dynamicLogWithPP xmobarPP {
        ppOutput  = hPutStrLn workspaceBar,
        ppSep     = " | ",
        ppCurrent = xmobarColor "#98c4f0" barBackground . wrap "[" "]",
        ppVisible = xmobarColor "#58738d" barBackground . wrap "[" "]",
        ppHidden  = xmobarColor barForeground barBackground . wrap "[" "]" . noScratchPad,
        ppLayout  = xmobarColor barForeground barBackground . wrap "{ " " }",
        ppTitle   = xmobarColor "#8eb157" barBackground . shorten 75,
        ppUrgent  = xmobarColor "#bb4b4b" barBackground . wrap "[" "]"
      } >> fadeInactiveLogHook 0.5
    }
    -- change workspace keybindings to not be "greedy" (move my focus to the
    -- screen displaying the workspace instead of moving the workspace to my
    -- screen)
    `additionalKeys` [((m .|. mod1Mask, k), windows $ f i)
         | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
         , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
    `additionalKeysP` [
      ("M-x",         kill),
      ("M-m",         sendMessage $ JumpToLayout "Full"),
      ("M-<Tab>",     windows W.focusDown),
      ("M-S-<Tab>",   windows W.focusUp),
      ("M-p",         namedScratchpadAction myScratchpads "scratchterm"),
      ("M-S-p",       spawn $ "~/bin/keyring prompt --paste"),
      ("M-z",         spawn $ "alock -cursor theme:name=xtr -auth pam"),
      ("M-q",         spawn $ "xmonad --restart"),

      -- adjust screen brightness
      -- ("M-b",         spawn $ "xbacklight -inc 10"),
      -- ("M-S-b",       spawn $ "xbacklight -dec 10"),

      -- mnemonics based on the shift version of the key:
      --   -,+ - increase/decrease volume
      ("M-=",         spawn $ "~/bin/volume 3+"),
      ("M--",         spawn $ "~/bin/volume 3-") ]
    `removeKeysP` [ ("M-r"), ("M-b") ]

  xmonad config
