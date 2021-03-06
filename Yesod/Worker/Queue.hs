module Yesod.Worker.Queue
( enqueueJob
, dequeueJob
, emptyQueue
) where

import Prelude
import Yesod.Worker.Types

import Control.Concurrent.STM
import qualified Data.Sequence as S

enqueue :: S.Seq a -> a -> S.Seq a
enqueue = (S.|>)

dequeue :: S.Seq a -> Maybe (a, S.Seq a)
dequeue s = case S.viewl s of
  x S.:< xs -> Just (x, xs)
  _         -> Nothing


-- | An empty queue, suitable for initializing the app queue at boot
emptyQueue :: IO JobQueue
emptyQueue = atomically $ newTVar S.empty

enqueueJob :: (Show a) => JobQueue -> a -> IO ()
enqueueJob qvar j = atomically $ modifyTVar qvar add
  where add q = enqueue q $ show j

dequeueJob :: JobQueue -> IO (Maybe String)
dequeueJob qvar = atomically $ do
  q <- readTVar qvar
  case dequeue q of
    Just (x,xs) -> do
      writeTVar qvar xs
      return $ Just x
    Nothing -> return Nothing
