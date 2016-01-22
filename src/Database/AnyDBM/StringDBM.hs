{- arch-tag: Support for persistent storage through strings
Copyright (C) 2005 John Goerzen <jgoerzen@complete.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
-}

{- |
   Module     : Database.AnyDBM.StringDBM
   Copyright  : Copyright (C) 2005 John Goerzen
   License    : GNU LGPL, version 2.1 or above

   Maintainer : John Goerzen <jgoerzen@complete.org>
   Stability  : provisional
   Portability: portable

Written by John Goerzen, jgoerzen\@complete.org

This 'Database.AnyDBM.AnyDBM' implementation is very simple.  It can store
data on-disk in a persistent fashion, using a very simple String
representation.  While the file is open, an in-memory cache is maintained.
The data is written out during a call to 'flush' or 'close'.
-}

module Database.AnyDBM.StringDBM (StringDBM,
                                  openStringDBM,
                                  openStringVDBM,
                                  SystemFS(..),
                                  IOMode(..)
                                 )
where
import Database.AnyDBM
import System.IO
import System.IO.HVFS
import System.IO.HVIO
import Data.HashTable.IO
import Control.Concurrent.MVar

{- | The type of the StringDBM instances. -}
data StringDBM = forall a. HVFSOpenable a => StringDBM (MVar ()) (BasicHashTable String String) IOMode a FilePath

{- | Opens a 'StringDBM' file.  Please note: only ReadMode, WriteMode,
and ReadWriteMode are supported for the IOMode.  AppendMode is not supported. 

>openStringDBM = openStringVDBM SystemFS
-}
openStringDBM :: FilePath -> IOMode -> IO StringDBM
openStringDBM = openStringVDBM SystemFS

{- | Opens a 'StringDBM' file.  Please note: only ReadMode, WriteMode,
and ReadWriteMode are supported for the IOMode.  AppendMode is not supported.

To work on your system's normal (real) filesystem, just specify
'SystemFS' for the first argument.
-}
openStringVDBM :: HVFSOpenable a => a -> FilePath -> IOMode -> IO StringDBM
openStringVDBM _ _ AppendMode = fail "openStringDBM: AppendMode is not supported"
openStringVDBM h fp ReadMode =
    do ht <- new
       lock <- newMVar ()
       vReadFile h fp >>= strToA ht
       return $ StringDBM lock ht ReadMode h fp
openStringVDBM h fp WriteMode =
    do ht <- new
       lock <- newMVar ()
       return $ StringDBM lock ht WriteMode h fp
openStringVDBM h fp ReadWriteMode =
    -- Nothing different to start with.  Later, we emulate WriteMode.
    -- Nothing is ever read after the object is created.
    do ht <- new
       lock <- newMVar ()
       d <- vDoesFileExist h fp
       if d
          then vReadFile h fp >>= strToA ht
          else return ()
       return $ StringDBM lock ht WriteMode h fp

g :: StringDBM -> BasicHashTable String String
g (StringDBM _ ht _ _ _) = ht

instance AnyDBM StringDBM where
    flushA (StringDBM lock ht WriteMode h fp) = withMVar lock $ \_ ->
        do s <- strFromA ht
           vWriteFile h fp s
    flushA _ = return ()

    insertA = insertA . g
    deleteA = deleteA . g
    lookupA = lookupA . g
    toListA = toListA . g
