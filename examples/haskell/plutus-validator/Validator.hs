{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE NoImplicitPrelude #-}

module SimpleValidator where

import PlutusTx
import PlutusTx.Prelude
import Plutus.V2.Ledger.Api
import Plutus.V2.Ledger.Contexts

{-|
  Simple Validator for Cardano Plutus
  Demonstrates functional smart contract development
-}

-- | Datum stored with the UTXO
data SimpleDatum = SimpleDatum
    { owner :: PubKeyHash
    , amount :: Integer
    }

PlutusTx.unstableMakeIsData ''SimpleDatum

-- | Redeemer for unlocking
data SimpleRedeemer = Unlock | Cancel

PlutusTx.unstableMakeIsData ''SimpleRedeemer

-- | Validator logic
{-# INLINABLE mkValidator #-}
mkValidator :: SimpleDatum -> SimpleRedeemer -> ScriptContext -> Bool
mkValidator datum redeemer ctx =
    case redeemer of
        Unlock -> traceIfFalse "Owner signature missing" signedByOwner
        Cancel -> traceIfFalse "Invalid cancellation" True
  where
    info :: TxInfo
    info = scriptContextTxInfo ctx

    signedByOwner :: Bool
    signedByOwner = txSignedBy info (owner datum)

-- | Compile validator
validator :: Validator
validator = mkValidatorScript $$(PlutusTx.compile [|| mkValidator ||])

-- | Validator hash
validatorHash :: ValidatorHash
validatorHash = validatorHash validator

-- | Script address
scriptAddress :: Address
scriptAddress = scriptHashAddress validatorHash
