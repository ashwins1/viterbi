import qualified Data.Array as A
import Data.Array ((!))
import Data.List (maximumBy)
import qualified Data.MemoCombinators as Memo
import Data.Function (on)

type Probability = Double

data Dynamics s o = Dynamics 
                  { priorProb      :: s -> Probability
                  , transitionProb :: s -> s -> Probability
                  , emissionProb   :: s -> o -> Probability
                  }

-- The following example shamelessly lifted from Wikipedia's "Viterbi algorithm" page
-- (http://en.wikipedia.org/wiki/Viterbi_algorithm)

data HealthState = Healthy | Fever 
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

data Symptom = Normal | Cold | Dizzy
  deriving (Eq, Ord, Show, Read, Enum, Bounded)

prior :: HealthState -> Probability
prior Healthy = 0.6
prior Fever   = 0.4

transitions :: HealthState -> HealthState -> Probability
transitions Healthy Healthy = 0.7
transitions Healthy Fever   = 0.3
transitions Fever Healthy   = 0.4
transitions Fever Fever     = 0.6

emissions :: HealthState -> Symptom -> Probability
emissions Healthy Normal = 0.5
emissions Healthy Cold   = 0.4
emissions Healthy Dizzy  = 0.1
emissions Fever Normal   = 0.1
emissions Fever Cold     = 0.3
emissions Fever Dizzy    = 0.6

healthDynamics = Dynamics prior transitions emissions

observedSymptoms :: A.Array Int Symptom
observedSymptoms = A.listArray (0, 2) [Normal, Cold, Dizzy]

viterbiAlgorithm :: (Enum s, Bounded s, Enum o, Bounded o) => Dynamics s o -> A.Array Int o -> A.Array Int s
viterbiAlgorithm dyn obs = A.listArray (lo, hi) [reconstructPath t | t <- [lo .. hi]]
  where tp = transitionProb dyn
        ep = emissionProb dyn
        pp = priorProb dyn
        allStates = [minBound .. maxBound]
        (lo, hi) = A.bounds obs
        reconstructPath = Memo.integral reconstructPath'
          where reconstructPath' t
                  | t == hi   = maximumBy (compare `on` (\st -> fst $ valueFunction st hi)) allStates
                  | otherwise = snd $ valueFunction (reconstructPath (t+1)) (t+1)
        valueFunction = Memo.memo2 Memo.enum Memo.integral valueFunction'
          where valueFunction' i t
                  | t == lo   = ((log $ pp i) + logEmitProb, i)
                  | otherwise = maximumBy (compare `on` fst) nextProbs
                    where logEmitProb = log $ ep i (obs ! t)
                          nextProbs   = [((fst $ valueFunction j (t-1)) + (log $ tp j i) + logEmitProb, j) | j <- allStates]
