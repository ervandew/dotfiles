import XMonad hiding ((|||))
import XMonad.Actions.WindowNavigation
import XMonad.Config.Desktop
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Accordion
import XMonad.Layout.Combo
import XMonad.Layout.LayoutCombinators
import XMonad.Layout.Renamed
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.StackTile
import XMonad.Layout.TwoPane
import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import XMonad.Util.WorkspaceCompare
import qualified XMonad.StackSet as W

myWorkspaces = ["1:main", "2:im/mail", "3:media", "4:vm"]
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
    className =? "Keyring" --> doFloat
  ]

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

main = do
  spawn "xrandr --auto"
  spawn "polybar-msg cmd quit ; polybar &"
  spawn "xset -b"
  spawn "xset r rate 250 30"
  spawn "xsetroot -cursor_name left_ptr"
  spawn "hsetroot -solid '#333333'"
  spawn "xmodmap ~/.config/xinit/xmodmap"
  spawn "pkill keynav ; keynav &"
  spawn "pkill warpd ; warpd &"
  spawn "pkill xcompmgr ; xcompmgr -c -r0 &"
  spawn "pkill -9 unclutter ; sleep 0.3 ; unclutter --timeout 2 &"
  config <-
    withWindowNavigation(xK_k, xK_h, xK_j, xK_l) $
    -- filter out NSP (named scratchpad) workspace
    addEwmhWorkspaceSort (pure (filterOutWs ["NSP"])) . ewmh $
    withUrgencyHook NoUrgencyHook $
    desktopConfig {
      borderWidth        = 1,
      modMask            = mod1Mask,
      normalBorderColor  = "#333333",
      focusedBorderColor = "#5884b0",
      focusFollowsMouse  = False,
      terminal           = "alacritty",
      workspaces         = myWorkspaces,
      layoutHook         = myLayout,
      logHook            = fadeInactiveLogHook 0.5,
      manageHook         =
        manageDocks <+>
        myManageHook <+>
        manageHook desktopConfig <+>
        namedScratchpadManageHook myScratchpads
    }
    `additionalKeysP` [
      ("M-x",         kill),
      ("M-m",         sendMessage $ JumpToLayout "Full"),
      ("M-<Tab>",     windows W.focusDown),
      ("M-S-<Tab>",   windows W.focusUp),
      ("M-p",         namedScratchpadAction myScratchpads "scratchterm"),
      ("M-S-p",       spawn $ "~/bin/keyring prompt --paste"),
      ("M-q",         spawn $ "xmonad --restart"),

      -- mnemonics based on the shift version of the key:
      --   -,+ - increase/decrease volume
      ("M-=",         spawn $ "~/bin/volume 3+"),
      ("M--",         spawn $ "~/bin/volume 3-") ]
    `removeKeysP` [ ("M-r"), ("M-b") ]

  xmonad config
