-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan@cs.uu.nl
-- Stability   :  experimental
-- Portability :  unknown
--
-----------------------------------------------------------------------------

module Top.TypeGraph.TypeGraphSolver
   ( TypeGraph, TypeGraphX, TypeGraphState
   , runTypeGraph, runTypeGraphPlusDoFirst, runTypeGraphPlusDoAtEnd, solveTypeGraph
   ) where

import Top.TypeGraph.TypeGraphMonad
import Top.TypeGraph.TypeGraphSubst
import Top.TypeGraph.TypeGraphState
import qualified Top.TypeGraph.Implementation as Impl
import Top.Solvers.SolveConstraints
import Top.Solvers.BasicMonad
import Top.States.TIState
import Top.States.SubstState
import Top.States.States
import Top.Constraints.Constraints
import Top.Qualifiers.Qualifiers
import Top.Types
import Control.Monad

type TypeGraphX info qs ext = SolveX info qs (TypeGraphState info) ext
type TypeGraph  info qs     = TypeGraphX info qs ()
 
instance HasTG (TypeGraphX info qs ext) info where
  tgGet   = do (_,(_,(z,_))) <- getX; return z
  tgPut z = do (x,(y,(_,w))) <- getX; putX (x,(y,(z,w)))
            
instance HasSubst (TypeGraphX info qs ext) info where
   substState = typegraphImpl
   
-----------------------------------------------------------------------------

instance HasTypeGraph (TypeGraphX info qs ext) info where
   addTermGraph            = lift1 Impl.addTermGraph
   addVertex               = lift2 Impl.addVertex
   addEdge                 = lift2 Impl.addEdge
   deleteEdge              = lift1 Impl.deleteEdge
   verticesInGroupOf       = lift1 Impl.verticesInGroupOf
   substituteTypeSafe      = lift1 Impl.substituteTypeSafe
   edgesFrom               = lift1 Impl.edgesFrom
   allPathsListWithout     = lift3 Impl.allPathsListWithout
   removeInconsistencies   = lift0 Impl.removeInconsistencies
   makeSubstitution        = lift0 Impl.makeSubstitution
   typeFromTermGraph       = lift1 Impl.typeFromTermGraph  
   markAsPossibleError     = lift1 Impl.markAsPossibleError
   getMarkedPossibleErrors = lift0 Impl.getMarkedPossibleErrors
   unmarkPossibleErrors    = lift0 Impl.unmarkPossibleErrors

----------------------------------------------
-- lift a function

lift0 :: (HasTG m info, HasTypeGraph m info) => Impl.TypeGraph info a -> m a
lift1 :: (HasTG m info, HasTypeGraph m info) => (t1 -> Impl.TypeGraph info a) -> t1 -> m a
lift2 :: (HasTG m info, HasTypeGraph m info) => (t1 -> t2 -> Impl.TypeGraph info a) -> t1 -> t2 -> m a
lift3 :: (HasTG m info, HasTypeGraph m info) => (t1 -> t2 -> t3 -> Impl.TypeGraph info a) -> t1 -> t2 -> t3 -> m a

lift0 f       = Impl.fromTypeGraph f 
lift1 f x     = Impl.fromTypeGraph $ f x 
lift2 f x y   = Impl.fromTypeGraph $ f x y
lift3 f x y z = Impl.fromTypeGraph $ f x y z

solveTypeGraph :: 
   ( IsState ext
   , Solvable constraint (TypeGraphX info qs ext)
   , QualifierList (TypeGraphX info qs ext) info qs qsInfo
   ) => 
     TypeGraphX info qs ext () ->
     TypeGraphX info qs ext () ->
     ClassEnvironment -> OrderedTypeSynonyms -> Int -> [constraint] ->
     TypeGraphX info qs ext (SolveResult info qs ext)
     
solveTypeGraph extraFirst extraEnd classEnv syns unique = 
   solveConstraints doFirst doAtEnd
      where
         doFirst = 
            do setUnique unique
               setTypeSynonyms syns
               setClassEnvironment classEnv
               extraFirst
         doAtEnd =
            do extraEnd
               solveResult

runTypeGraph:: 
   ( IsState ext
   , Solvable constraint (TypeGraphX info qs ext)
   , QualifierList (TypeGraphX info qs ext) info qs qsInfo
   ) => 
     SolverX constraint info qs ext

runTypeGraph = 
   runTypeGraphPlusDoAtEnd (return ())

runTypeGraphPlusDoFirst :: 
   ( IsState ext
   , Solvable constraint (TypeGraphX info qs ext)
   , QualifierList (TypeGraphX info qs ext) info qs qsInfo
   ) => 
     TypeGraphX info qs ext () -> SolverX constraint info qs ext

runTypeGraphPlusDoFirst todo classEnv syns unique = 
   eval . solveTypeGraph todo (return ()) classEnv syns unique
   
runTypeGraphPlusDoAtEnd :: 
   ( IsState ext
   , Solvable constraint (TypeGraphX info qs ext)
   , QualifierList (TypeGraphX info qs ext) info qs qsInfo
   ) => 
     TypeGraphX info qs ext () -> SolverX constraint info qs ext

runTypeGraphPlusDoAtEnd todo classEnv syns unique = 
   eval . solveTypeGraph (return ()) todo classEnv syns unique