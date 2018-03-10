
module SuffixTree.Util where

import qualified Data.MultiSet as MS
import           Control.Arrow       ((&&&))
import qualified Data.IntMap         as I
import qualified Data.List           as L
import           Data.Text.Lazy      (Text, cons)
import qualified Data.Text.Lazy      as T
import           Data.Vector         (Vector)
import qualified Data.Vector         as V
import qualified Data.Vector.Mutable as MV
import           Prelude             (String)
import           Protolude           hiding (Text)



tail :: Text -> Text
tail "" = ""
tail xs = T.tail xs

removeHeads :: [Text] -> [Text]
removeHeads []        = []
removeHeads("" : xss) = removeHeads xss
removeHeads(xs : xss) = T.tail xs : removeHeads xss

fst3 :: (a, b, c) -> a
fst3 (x, _, _) = x


fstEq :: Text -> Text -> Bool
fstEq "" _  = undefined
fstEq _ ""  = undefined
fstEq xs ys = T.head xs == T.head ys


headEq :: Char -> Text -> Bool
headEq _ "" = False
headEq a xs = a == T.head xs


removeDuplicates :: Text -> Text
removeDuplicates ""  =  ""
removeDuplicates t   =  x `cons` removeDuplicates withoutX
    where x = T.head t
          withoutX = T.filter (\y -> x /= y) (T.tail t)


listify :: (a, a) -> [a]
listify (a, b) = [a, b]

heads :: [Text] -> String
heads = foldr (\x acc -> if T.null x then acc else T.head x : acc) []


countingSort :: Vector Text -> [[Text]]
countingSort = L.groupBy fstEq . V.toList . countingSortV


countingSortV :: Vector Text -> Vector Text
countingSortV input = V.create $ do
    let input' = V.init input
        lo = ord $ V.minimum $ T.head <$> input'
        hi = ord $ V.maximum $ T.head  <$> input'

    offsets <- V.thaw . V.prescanl (+) 0 $ V.create $ do
        counts <- MV.replicate (hi - lo + 1) 0
        V.forM_ input' $ \x ->
            MV.modify counts succ (ord (T.head x) - lo)
        return counts

    output <- MV.new (V.length input')

    V.forM_ input' $ \x -> do
        let i = ord $ T.head x
        ix <- MV.read offsets (i - lo)
        MV.write output ix x
        MV.modify offsets succ (i - lo)

    return output


