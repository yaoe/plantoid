/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Contract, ContractFactory, Overrides } from "@ethersproject/contracts";

import type { DefaultCallbackHandler } from "./DefaultCallbackHandler";

export class DefaultCallbackHandlerFactory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(overrides?: Overrides): Promise<DefaultCallbackHandler> {
    return super.deploy(overrides || {}) as Promise<DefaultCallbackHandler>;
  }
  getDeployTransaction(overrides?: Overrides): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): DefaultCallbackHandler {
    return super.attach(address) as DefaultCallbackHandler;
  }
  connect(signer: Signer): DefaultCallbackHandlerFactory {
    return super.connect(signer) as DefaultCallbackHandlerFactory;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DefaultCallbackHandler {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as DefaultCallbackHandler;
  }
}

const _abi = [
  {
    inputs: [],
    name: "NAME",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "VERSION",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "",
        type: "uint256[]",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "onERC1155BatchReceived",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "onERC1155Received",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "onERC721Received",
    outputs: [
      {
        internalType: "bytes4",
        name: "",
        type: "bytes4",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    name: "tokensReceived",
    outputs: [],
    stateMutability: "pure",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b5061059b806100206000396000f3fe608060405234801561001057600080fd5b506004361061007c5760003560e01c8063a3f4df7e1161005b578063a3f4df7e146100fb578063bc197c8114610144578063f23a6e6114610166578063ffa1ad741461018657600080fd5b806223de291461008157806301ffc9a71461009b578063150b7a02146100c3575b600080fd5b61009961008f3660046102b3565b5050505050505050565b005b6100ae6100a93660046104df565b6101aa565b60405190151581526020015b60405180910390f35b6100e26100d13660046103f8565b630a85bd0160e11b95945050505050565b6040516001600160e01b031990911681526020016100ba565b6101376040518060400160405280601881526020017f44656661756c742043616c6c6261636b2048616e646c6572000000000000000081525081565b6040516100ba9190610510565b6100e261015236600461035e565b63bc197c8160e01b98975050505050505050565b6100e2610174366004610467565b63f23a6e6160e01b9695505050505050565b610137604051806040016040528060058152602001640312e302e360dc1b81525081565b60006001600160e01b03198216630271189760e51b14806101db57506001600160e01b03198216630a85bd0160e11b145b806101f657506001600160e01b031982166301ffc9a760e01b145b92915050565b803573ffffffffffffffffffffffffffffffffffffffff8116811461022057600080fd5b919050565b60008083601f84011261023757600080fd5b50813567ffffffffffffffff81111561024f57600080fd5b6020830191508360208260051b850101111561026a57600080fd5b9250929050565b60008083601f84011261028357600080fd5b50813567ffffffffffffffff81111561029b57600080fd5b60208301915083602082850101111561026a57600080fd5b60008060008060008060008060c0898b0312156102cf57600080fd5b6102d8896101fc565b97506102e660208a016101fc565b96506102f460408a016101fc565b955060608901359450608089013567ffffffffffffffff8082111561031857600080fd5b6103248c838d01610271565b909650945060a08b013591508082111561033d57600080fd5b5061034a8b828c01610271565b999c989b5096995094979396929594505050565b60008060008060008060008060a0898b03121561037a57600080fd5b610383896101fc565b975061039160208a016101fc565b9650604089013567ffffffffffffffff808211156103ae57600080fd5b6103ba8c838d01610225565b909850965060608b01359150808211156103d357600080fd5b6103df8c838d01610225565b909650945060808b013591508082111561033d57600080fd5b60008060008060006080868803121561041057600080fd5b610419866101fc565b9450610427602087016101fc565b935060408601359250606086013567ffffffffffffffff81111561044a57600080fd5b61045688828901610271565b969995985093965092949392505050565b60008060008060008060a0878903121561048057600080fd5b610489876101fc565b9550610497602088016101fc565b94506040870135935060608701359250608087013567ffffffffffffffff8111156104c157600080fd5b6104cd89828a01610271565b979a9699509497509295939492505050565b6000602082840312156104f157600080fd5b81356001600160e01b03198116811461050957600080fd5b9392505050565b600060208083528351808285015260005b8181101561053d57858101830151858201604001528201610521565b8181111561054f576000604083870101525b50601f01601f191692909201604001939250505056fea2646970667358221220f19b46c08ee4006ff195f3a725617b372366ddb1e4b011a8be16605d12cf606a64736f6c63430008070033";
