-- Taken from http://hpaste.org/44409/perlayoutkeys?pid=44409&lang_44409=cpp
-- (This module is just a barely modified copy of PerWorkspaceKeys.hs)
--
-----------------------------------------------------------------------------

module XMonad.Actions.PerLayoutKeys (
                                 -- * Usage
                                 -- $usage
                                 chooseAction,
                                 bindOnLayout
                                ) where

import XMonad
import XMonad.StackSet as S

-- $usage
--
-- You can use this module with the following in your @~\/.xmonad\/xmonad.hs@:
--
-- >  import XMonad.Actions.PerLayoutKeys
--
-- >   ,((0, xK_F2), bindOnLayout [("1", spawn "rxvt"), ("2", spawn "xeyes"), ("", spawn "xmessage hello")])
--
-- For detailed instructions on editing your key bindings, see
-- "XMonad.Doc.Extending#Editing_key_bindings".

-- | Uses supplied function to decide which action to run depending on current layout name.
chooseAction :: (String->X()) -> X()
chooseAction f = withWindowSet (f . description . S.layout . S.workspace . S.current)

-- | If current layout is listed, run appropriate action (only the first match counts!)
-- If it isn't listed, then run default action (marked with empty string, \"\"), or do nothing if default isn't supplied.
bindOnLayout :: [(String, X())] -> X()
bindOnLayout bindings = chooseAction chooser where
    chooser ws = case lookup ws bindings of
        Just action -> action
        Nothing -> case lookup "" bindings of
            Just action -> action
            Nothing -> return ()
