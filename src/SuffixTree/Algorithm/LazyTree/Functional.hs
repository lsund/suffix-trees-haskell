
module SuffixTree.Algorithm.LazyTree.Functional where

import           Data.Function
import           Data.List                  (nub)
import           Data.Text.Lazy                  as Text hiding (all, init,
                                                     map)
import           Prelude                    (init, String)
import           Protolude                  hiding (length, Text)

import           SuffixTree.Data.Label      (Label (..))
import           SuffixTree.Data.SuffixTree
import           SuffixTree.Util as Util

-------------------------------------------------------------------------------
-- Atomic Suffix Tree


edgeAST :: EdgeFunction
edgeAST xs = (0, xs)


-------------------------------------------------------------------------------
-- Compact Suffix Tree: Extracts the largest common suffix for each branch


edgeCST :: EdgeFunction
edgeCST []                      = (0, [""])
edgeCST ("" : xss)              = edgeCST xss
edgeCST [s]                     = (length s, [""])
edgeCST (xs : xss) =
    let
        (h, t) = (Text.head xs, Text.tail xs)
        (lcp, xs') = edgeCST (t : removeHeads xss)
    in
        if allHeadsEq h xss
            then (succ lcp, xs')
            else  (0, xs : xss)
    where
        allHeadsEq c = all ((==) c . Text.head)


-------------------------------------------------------------------------------
-- Functional LazyTree

lazyTree :: EdgeFunction -> Text -> STree
lazyTree edgeFun x = lazyTree' (fromIntegral $ length x) (init $ Text.tails x)
    where
        lazyTree' i [""]     = Leaf i
        lazyTree' i suffixes = Branch (foldr' (addEdge i suffixes) [] (nub $ heads suffixes))
        addEdge i suffixes a edges =
            let
                aSuffixes = filterSuffixes a suffixes
                (lcp, rests) = edgeFun aSuffixes
            in
                case aSuffixes of
                    (mark : _) -> makeEdge mark lcp rests : edges
                    []         -> edges
            where
                newLabel mark lcp       = Label (a `cons` mark) (succ lcp)
                descendTree lcp         = lazyTree' (i - succ lcp)
                makeEdge mark lcp rests = Edge (newLabel mark lcp)
                                                (descendTree lcp rests)


heads :: [Text] -> String
heads [] = []
heads [""] = []
heads (x : xs) = Text.head x : heads xs

filterSuffixes :: Char -> [Text] -> [Text]
filterSuffixes c = map Util.tail . Protolude.filter (headEq c)
