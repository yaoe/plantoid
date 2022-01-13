/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Contract, ContractFactory, Overrides } from "@ethersproject/contracts";

import type { FallbackManager } from "./FallbackManager";

export class FallbackManagerFactory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(overrides?: Overrides): Promise<FallbackManager> {
    return super.deploy(overrides || {}) as Promise<FallbackManager>;
  }
  getDeployTransaction(overrides?: Overrides): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): FallbackManager {
    return super.attach(address) as FallbackManager;
  }
  connect(signer: Signer): FallbackManagerFactory {
    return super.connect(signer) as FallbackManagerFactory;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): FallbackManager {
    return new Contract(address, _abi, signerOrProvider) as FallbackManager;
  }
}

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "handler",
        type: "address",
      },
    ],
    name: "ChangedFallbackHandler",
    type: "event",
  },
  {
    stateMutability: "nonpayable",
    type: "fallback",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "handler",
        type: "address",
      },
    ],
    name: "setFallbackHandler",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506101ab806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c8063f08a032314610084575b7f6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d580548061005557005b36600080373360601b365260008060143601600080855af190503d6000803e8061007e573d6000fd5b503d6000f35b610097610092366004610145565b610099565b005b6100a1610108565b6100c9817f6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d555565b6040516001600160a01b03821681527f5ac6c46c93c8d0e53714ba3b53db3e7c046da994313d7ed0d192028bc7c228b09060200160405180910390a150565b3330146101435760405162461bcd60e51b8152602060048201526005602482015264475330333160d81b604482015260640160405180910390fd5b565b60006020828403121561015757600080fd5b81356001600160a01b038116811461016e57600080fd5b939250505056fea2646970667358221220a318ef4e61286fc7b7cb14e383f0f5f7669e84a3ad0fefb4c813f21149cbfe7f64736f6c63430008070033";