-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan@cs.uu.nl
-- Stability   :  experimental
-- Portability :  unknown
--
-- A predicate constraint is a (single parameter) type class constraint constraint
-- that is part of a context.
--
-----------------------------------------------------------------------------

module Top.Constraints.PredicateConstraint where

import Top.Types
import Top.Constraints.Constraints
import Top.States.TIState

data PredicateConstraint info = PredicateConstraint Predicate info

-- |The constructor of a predicate constraint.
predicate :: Solvable (PredicateConstraint info) m => Predicate -> info -> Constraint m
predicate p info = liftConstraint (PredicateConstraint p info)

instance Show info => Show (PredicateConstraint info) where
   show (PredicateConstraint p info) =
      show p++"   {"++show info++"}"
     
instance Substitutable (PredicateConstraint info) where

   sub |-> (PredicateConstraint p info) =
      PredicateConstraint (sub |-> p) info
      
   ftv (PredicateConstraint p _) = 
      ftv p  
      
instance (Show info, HasTI m info) =>
            Solvable (PredicateConstraint info) m where

   solveConstraint (PredicateConstraint p info) = 
      addPredicate (p, info)
