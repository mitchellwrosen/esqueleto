{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, FunctionalDependencies, TypeFamilies, EmptyDataDecls #-}
module Database.Esqueleto.Internal.Language
  ( Esqueleto(..)
  , from
  , OrderBy
  ) where

import Control.Applicative (Applicative(..), (<$>))
import Database.Persist.GenericSql
import Database.Persist.Store


-- | Finally tagless representation of Esqueleto's EDSL.
class (Functor query, Applicative query, Monad query) =>
      Esqueleto query expr backend | query -> expr backend, expr -> query backend where
  -- | (Internal) Single entity version of 'from'.
  fromSingle :: ( PersistEntity val
                , PersistEntityBackend val ~ backend)
             => query (expr (Entity val))

  -- | @WHERE@ clause: restrict the query's result.
  where_ :: expr (Single Bool) -> query ()

  -- | @ORDER BY@ clause. See also 'asc' and 'desc'.
  orderBy :: [expr OrderBy] -> query ()

  -- | Ascending order of this field or expression.
  asc :: PersistField a => expr (Single a) -> expr OrderBy

  -- | Descending order of this field or expression.
  desc :: PersistField a => expr (Single a) -> expr OrderBy

  -- | Execute a subquery in an expression.
  sub  :: PersistField a => query (expr (Single a)) -> expr (Single a)

  -- | Project a field of an entity.
  (^.) :: (PersistEntity val, PersistField typ) =>
          expr (Entity val) -> EntityField val typ -> expr (Single typ)

  -- | Lift a constant value from Haskell-land to the query.
  val  :: PersistField typ => typ -> expr (Single typ)

  -- | @IS NULL@ comparison.
  isNothing :: PersistField typ => expr (Single (Maybe typ)) -> expr (Single Bool)

  -- | Analog to 'Just', promotes a value of type @typ@ into one
  -- of type @Maybe typ@.  It should hold that @val . Just ===
  -- just . val@.
  just :: expr (Single typ) -> expr (Single (Maybe typ))

  -- | @NULL@ value.
  nothing :: expr (Single (Maybe typ))

  not_ :: expr (Single Bool) -> expr (Single Bool)

  (==.) :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)
  (>=.) :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)
  (>.)  :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)
  (<=.) :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)
  (<.)  :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)
  (!=.) :: PersistField typ => expr (Single typ) -> expr (Single typ) -> expr (Single Bool)

  (&&.) :: expr (Single Bool) -> expr (Single Bool) -> expr (Single Bool)
  (||.) :: expr (Single Bool) -> expr (Single Bool) -> expr (Single Bool)

  (+.)  :: (Num a, PersistField a) => expr (Single a) -> expr (Single a) -> expr (Single a)
  (-.)  :: (Num a, PersistField a) => expr (Single a) -> expr (Single a) -> expr (Single a)
  (/.)  :: (Num a, PersistField a) => expr (Single a) -> expr (Single a) -> expr (Single a)
  (*.)  :: (Num a, PersistField a) => expr (Single a) -> expr (Single a) -> expr (Single a)

-- Fixity declarations
infixl 9 ^.
infixl 7 *., /.
infixl 6 +., -.
infix  4 ==., >=., >., <=., <., !=.
infixr 3 &&.
infixr 2 ||.


-- | Phantom type used by 'orderBy', 'asc' and 'desc'.
data OrderBy


-- | @FROM@ clause: bring an entity into scope.
--
-- The following types implement 'from':
--
--  * @Expr (Entity val)@, which brings a single entity into scope.
--
--  * Tuples of any other types supported by 'from'.  Calling
--  'from' multiple times is the same as calling 'from' a
--  single time and using a tuple.
--
-- Note that using 'from' for the same entity twice does work
-- and corresponds to a self-join.  You don't even need to use
-- two different calls to 'from', you may use a tuple.
from :: From query expr backend a => (a -> query b) -> query b
from = (from_ >>=)


class Esqueleto query expr backend => From query expr backend a where
  from_ :: query a

instance ( Esqueleto query expr backend
         , PersistEntity val
         , PersistEntityBackend val ~ backend
         ) => From query expr backend (expr (Entity val)) where
  from_ = fromSingle

instance ( From query expr backend a
         , From query expr backend b
         ) => From query expr backend (a, b) where
  from_ = (,) <$> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         ) => From query expr backend (a, b, c) where
  from_ = (,,) <$> from_ <*> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         , From query expr backend d
         ) => From query expr backend (a, b, c, d) where
  from_ = (,,,) <$> from_ <*> from_ <*> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         , From query expr backend d
         , From query expr backend e
         ) => From query expr backend (a, b, c, d, e) where
  from_ = (,,,,) <$> from_ <*> from_ <*> from_ <*> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         , From query expr backend d
         , From query expr backend e
         , From query expr backend f
         ) => From query expr backend (a, b, c, d, e, f) where
  from_ = (,,,,,) <$> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         , From query expr backend d
         , From query expr backend e
         , From query expr backend f
         , From query expr backend g
         ) => From query expr backend (a, b, c, d, e, f, g) where
  from_ = (,,,,,,) <$> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_

instance ( From query expr backend a
         , From query expr backend b
         , From query expr backend c
         , From query expr backend d
         , From query expr backend e
         , From query expr backend f
         , From query expr backend g
         , From query expr backend h
         ) => From query expr backend (a, b, c, d, e, f, g, h) where
  from_ = (,,,,,,,) <$> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_ <*> from_
