
module LazyTree.Functional where

import Data.Tree

import Protolude
import Util

-------------------------------------------------------------------------------
-- Data

type SuffixList a = [[a]]

type Label a = ([a], Int)

type Alphabet a = [a]

data STree a = Leaf | Branch [(Label a, STree a)] deriving (Eq, Show)

type EdgeFunction a = SuffixList a -> (Int, SuffixList a)


-------------------------------------------------------------------------------
-- Conversion


toTree :: STree Char -> Tree (Label Char)
toTree t = unfoldTree tuplize $ wrapRoot t
    where tuplize (s, Leaf)      = (s, [])
          tuplize (s, Branch xs) = (s, xs)
          wrapRoot st = (("x", 1 :: Int), st)


-------------------------------------------------------------------------------
-- Atomic Suffix Tree


edgeAST :: Eq a => EdgeFunction a
edgeAST xs = (0, xs)


-------------------------------------------------------------------------------
-- Position Suffix Tree


-- Takes a list of suffixes and removes the ones that occur in other suffixes
removeNested :: (Eq a) => [[a]] -> [[a]]
removeNested []                      = []
removeNested ([] : _ : _ )           = []
removeNested [s]                     = [s]
removeNested suffix@((x : xs) : xss)
    | (not . any (headEq x)) xss     = map tail removed
    | otherwise                      = suffix
        where
            removed                  = removeNested (xs : map tail xss)


edgePST :: Eq a => EdgeFunction a
edgePST = pstSplit . removeNested
    where
        pstSplit [x] = (length x, [[]])
        pstSplit xs  = (0, xs)


-------------------------------------------------------------------------------
-- Compact Suffix Tree: Extracts the largest common suffix for each branch


edgeCST :: Eq a => EdgeFunction a
edgeCST []                      = (-1, [[]])
edgeCST ([] : _ : _ )           = (-1, [[]])
edgeCST [s]                     = (length s, [[]])
edgeCST suffix@((x : xs) : xss)
  | allStartsWith x xss         = (succ lcp, xs')
  | otherwise                   = (0, suffix)
    where
        (lcp, xs')              = edgeCST (xs : map tail xss)
        allStartsWith c = null . filter (not . headEq c)


suffixes :: [a] -> SuffixList a
suffixes = tails


-------------------------------------------------------------------------------
-- Functional LazyTree


lazyTree :: Eq a => EdgeFunction a -> Alphabet a -> [a] -> STree a
lazyTree edge as = tree . suffixes
    where
        tree [[]]    = Leaf
        tree ss      = Branch (map (treeFor ss) as)
        treeFor ss a = ((a : xs, succ lcp), tree xs')
            where
                startsWith c = map tail . filter (headEq c)
                (xs : xss)   = startsWith a ss
                (lcp, xs')   = edge (xs : xss)


-------------------------------------------------------------------------------
-- Public API

lazyAST :: Eq a => [a] -> [a] -> STree a
lazyAST = lazyTree edgeAST

lazyPST :: Eq a => [a] -> [a] -> STree a
lazyPST = lazyTree edgePST

lazyCST :: Eq a => [a] -> [a] -> STree a
lazyCST = lazyTree edgeCST
