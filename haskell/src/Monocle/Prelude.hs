{-# LANGUAGE TemplateHaskell #-}

-- | An augmented relude with extra package such as time and aeson.
module Monocle.Prelude
  ( module Relude,
    fromFixed,
    double2Float,
    orDie,
    getExn,
    getEnv',
    headMaybe,

    -- * streaming
    Stream,
    Of (..),
    toVector,

    -- * mmoprh
    hoist,

    -- * exceptions
    MonadThrow,
    MonadMask,

    -- * tests
    Assertion,
    assertEqual,
    assertFailure,

    -- * relude extra
    groupBy,
    average,

    -- * data.fixed
    Fixed (..),
    Deci,
    Pico,

    -- * custom numerical newtype
    Count,
    countToWord,
    countToDeci,
    naturalToCount,

    -- * say
    sayErr,
    monocleLog,

    -- * time
    UTCTime,
    Monocle.Prelude.getCurrentTime,
    addUTCTime,
    elapsedSeconds,
    nominalDiffTimeToSeconds,
    diffUTCTime,
    formatTime',
    threadDelay,
    parseDateValue,
    dropTime,

    -- * qq-literals
    utctime,

    -- * lens
    Lens',
    lens,
    mapMOf,
    view,
    over,

    -- * aeson
    FromJSON (..),
    ToJSON (..),
    Value,
    encode,

    -- * bloodhound
    BH.MonadBH,
    BH.DocId,
    BH.BulkOperation (..),
    simpleSearch,
    doSearch,
    mkAnd,
    mkOr,
    mkNot,
    mkTerm,

    -- * proto3
    fromPBEnum,
  )
where

import Control.Concurrent (threadDelay)
import qualified Control.Foldl as L
import Control.Lens (Lens', lens, mapMOf, over, view)
import Control.Monad.Catch (MonadMask, MonadThrow)
import Control.Monad.Morph (hoist)
import Data.Aeson (FromJSON (..), ToJSON (..), Value, encode)
import Data.Fixed (Deci, Fixed (..), HasResolution (resolution), Pico)
import Data.Time
import Data.Time.Clock (getCurrentTime)
import Data.Vector (Vector)
import qualified Database.Bloodhound as BH
import GHC.Float (double2Float)
import Language.Haskell.TH.Quote (QuasiQuoter)
import Proto3.Suite (Enumerated (..))
import QQLiterals (qqLiteral)
import Relude
import Relude.Extra.Foldable (average)
import Relude.Extra.Group (groupBy)
import Say (sayErr)
import Streaming (Of (..))
import Streaming.Prelude (Stream)
import qualified Streaming.Prelude as S
import Test.Tasty.HUnit

eitherParseUTCTime :: String -> Either String UTCTime
eitherParseUTCTime x = maybe (Left ("Failed to parse time " <> x)) Right (readMaybe (x <> " Z"))

utctime :: QuasiQuoter
utctime = qqLiteral eitherParseUTCTime 'eitherParseUTCTime

-- | dropTime ensures the encoded date does not have millisecond.
-- This actually discard hour differences
dropTime :: UTCTime -> UTCTime
dropTime (UTCTime day _sec) = UTCTime day 0

headMaybe :: [a] -> Maybe a
headMaybe xs = head <$> nonEmpty xs

getEnv' :: Text -> IO Text
getEnv' var = do
  val <- toText . exceptEnv <$> lookupEnv (toString var)
  return $! val
  where
    exceptEnv = fromMaybe (error $ "ERROR: Missing environment variable named " <> var)

-- | A lifted version of getCurrentTime
getCurrentTime :: MonadIO m => m UTCTime
getCurrentTime = liftIO Data.Time.Clock.getCurrentTime

-- | Return the seconds elapsed between a and b
-- >>> elapsedSeconds [utctime|2000-01-01 00:00:00|] [utctime|2000-01-01 01:00:00|]
-- 3600.000000000000
elapsedSeconds :: UTCTime -> UTCTime -> Pico
elapsedSeconds a b = nominalDiffTimeToSeconds $ diffUTCTime b a

-- | Helper to format time without timezone
formatTime' :: Text -> UTCTime -> Text
formatTime' formatText = toText . formatTime defaultTimeLocale (toString formatText)

-- | Helper
parseDateValue :: String -> Maybe UTCTime
parseDateValue str = tryParse "%F" <|> tryParse "%F %T %Z"
  where
    tryParse fmt = parseTimeM False defaultTimeLocale fmt str

-- | Numerical type to count documents
newtype Count = MkCount Word32
  deriving newtype (Show, Eq, Ord, Enum, Real, Integral, FromJSON)

countToWord :: Count -> Word32
countToWord (MkCount x) = x

countToDeci :: Count -> Deci
countToDeci (MkCount x) = fromInteger (toInteger x)

naturalToCount :: Natural -> Count
naturalToCount = MkCount . fromInteger . toInteger

-- | A special Num instance that prevent arithmetic underflow
instance Num Count where
  MkCount a - MkCount b
    | b > a = MkCount 0
    | otherwise = MkCount $ a - b

  MkCount a + MkCount b = MkCount $ a + b
  MkCount a * MkCount b = MkCount $ a * b
  signum (MkCount a) = MkCount $ signum a
  fromInteger x = MkCount $ fromInteger x
  abs x = x

-- | From https://hackage.haskell.org/package/astro-0.4.3.0/docs/src/Data.Astro.Utils.html#fromFixed
fromFixed :: (Fractional a, HasResolution b) => Fixed b -> a
fromFixed fv@(MkFixed v) = fromIntegral v / fromIntegral (resolution fv)

-- | From https://www.haskellforall.com/2021/05/the-trick-to-avoid-deeply-nested-error.html
orDie :: Maybe a -> b -> Either b a
Just a `orDie` _ = Right a
Nothing `orDie` err = Left err

getExn :: (ToText e, HasCallStack) => Either e a -> a
getExn (Right x) = x
getExn (Left err) = error (toText err)

monocleLog :: MonadIO m => Text -> m ()
monocleLog = sayErr

fromPBEnum :: Enumerated a -> a
fromPBEnum (Enumerated (Left x)) = error $ "Unknown enum value: " <> show x
fromPBEnum (Enumerated (Right x)) = x

-------------------------------------------------------------------------------
-- Streaming helpers

-- | 'toVector' is an efficient convertion of stream into a vector.
--   though we should be using a toChunkedVector :: Size -> Stream -> [Vector]
toVector :: L.PrimMonad m => Stream (Of a) m () -> m (Vector a)
toVector s = do
  res :> _ <- L.impurely S.foldM L.vectorM s
  pure res

-------------------------------------------------------------------------------
-- Bloodhound helpers

-- | Helper search func that can be replaced by a scanSearch
doSearch :: (FromJSON a, MonadThrow m, BH.MonadBH m) => BH.IndexName -> BH.Search -> m (BH.SearchResult a)
doSearch indexName search = do
  -- monocleLog . decodeUtf8 . encode $ search
  rawResp <- BH.searchByIndex indexName search
  -- monocleLog $ show rawResp
  resp <- BH.parseEsResponse rawResp
  case resp of
    Left _e -> handleError rawResp
    Right x -> pure x
  where
    handleError resp = do
      monocleLog (show resp)
      error "Elastic response failed"

simpleSearch :: (FromJSON a, MonadThrow m, BH.MonadBH m) => BH.IndexName -> BH.Search -> m [BH.Hit a]
simpleSearch indexName search = BH.hits . BH.searchHits <$> doSearch indexName search

mkAnd :: [BH.Query] -> BH.Query
mkAnd andQ = BH.QueryBoolQuery $ BH.mkBoolQuery [] (BH.Filter <$> andQ) [] []

mkOr :: [BH.Query] -> BH.Query
mkOr orQ = BH.QueryBoolQuery $ BH.mkBoolQuery [] [] [] orQ

mkNot :: [BH.Query] -> BH.Query
mkNot notQ = BH.QueryBoolQuery $ BH.mkBoolQuery [] [] notQ []

mkTerm :: Text -> Text -> BH.Query
mkTerm name value = BH.TermQuery (BH.Term name value) Nothing
