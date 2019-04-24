//! # Contract
#[allow(dead_code)]
mod error;

pub use self::error::Error;
use ethabi::param_type::{ParamType, Reader};
use ethabi::token::{LenientTokenizer, Token, Tokenizer};
use ethabi::{encode, Contract, Function};
use hex;

///// Contract specification
//#[derive(Clone, Debug, Deserialize)]
//pub struct Contract {
//    abi: Interface,
//}

//impl Contract {
//    /// Try to convert deserialized vector to Contract ABI.
//    ///
//    /// # Arguments
//    ///
//    /// * `DATA` - A byte slice
//    ///
//    pub fn try_from(data: &[u8]) -> Result<Self, Error> {
//        let abi = Contract::load(data)?;
//        Ok(Contract { abi })
//    }

/// Returns specification of contract function given the function name.
pub fn get_function(contract: &Contract, name: String) -> Option<Function> {
    match contract.function(&name) {
        Ok(f) => Some(Function::from(f.to_owned())),
        _ => None,
    }
}

/// Encode ABI function call with input params
pub fn serialize_function_call(
    contract: &Contract,
    name: String,
    params: Vec<Token>,
) -> Result<Vec<u8>, Error> {
    let f = contract.function(&name).unwrap();
    f.encode_call(params).map_err(From::from)
}

/// Encode ABI input params to hex string
pub fn serialize_params(types: &[String], values: Vec<String>) -> Result<String, Error> {
    let types: Result<Vec<ParamType>, _> = types.iter().map(|s| Reader::read(s)).collect();

    let types = try!(types);

    let params: Vec<_> = types.into_iter().zip(values.into_iter()).collect();

    let tokens = params
        .iter()
        .map(|&(ref param, ref value)| LenientTokenizer::tokenize(param, value))
        .collect::<Result<_, _>>()?;

    let result = encode(tokens);

    Ok(hex::encode(result))
}
//}

//impl fmt::Display for Contract {
//    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//        write!(f, "{:?}", self.abi)
//    }
//}

#[cfg(test)]
mod tests {
    use super::*;
    use ethabi::{Contract, Function as FunctionInterface, Param, ParamType};

    #[test]
    fn should_display_contract_abi() {
        let c = b"[{\"constant\":true,\"inputs\":[],\"name\":\"name\",\"outputs\":[{\"name\":\"\",\
                 \"type\":\"string\"}],\"payable\":false,\"type\":\"function\"}]";
        let contract = Contract::load(c).unwrap();
        format!("{}", contract);
    }

    #[test]
    fn should_return_correct_function() {
        let c = b"[{\"constant\":true,\"inputs\":[{\"name\":\"\",\"type\":\"address\"}],\"name\":\
                 \"balanceOf\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":\
                 false,\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"name\",\
                 \"outputs\":[{\"name\":\"\",\"type\":\"string\"}],\"payable\":false,\"type\":\
                 \"function\"}]";
        let interface = FunctionInterface {
            name: "balanceOf".to_owned(),
            inputs: vec![Param {
                name: "".to_owned(),
                kind: ParamType::Address,
            }],
            outputs: vec![Param {
                name: "a".to_owned(),
                kind: ParamType::Uint(256),
            }],
        };
        let contract = Contract::try_from(c).unwrap();
        let f = contract.get_function("balanceOf".to_string()).unwrap();
        assert_eq!(f.input_params(), Function::new(interface).input_params());
    }
}
