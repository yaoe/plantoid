/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
} from "ethers";
import {
  Contract,
  ContractTransaction,
  Overrides,
  CallOverrides,
} from "@ethersproject/contracts";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";

interface IAvatarInterface extends ethers.utils.Interface {
  functions: {
    "disableModule(address,address)": FunctionFragment;
    "enableModule(address)": FunctionFragment;
    "execTransactionFromModule(address,uint256,bytes,uint8)": FunctionFragment;
    "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)": FunctionFragment;
    "getModulesPaginated(address,uint256)": FunctionFragment;
    "isModuleEnabled(address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "disableModule",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "enableModule",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "execTransactionFromModule",
    values: [string, BigNumberish, BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "execTransactionFromModuleReturnData",
    values: [string, BigNumberish, BytesLike, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "getModulesPaginated",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "isModuleEnabled",
    values: [string]
  ): string;

  decodeFunctionResult(
    functionFragment: "disableModule",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "enableModule",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "execTransactionFromModule",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "execTransactionFromModuleReturnData",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getModulesPaginated",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isModuleEnabled",
    data: BytesLike
  ): Result;

  events: {};
}

export class IAvatar extends Contract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  on(event: EventFilter | string, listener: Listener): this;
  once(event: EventFilter | string, listener: Listener): this;
  addListener(eventName: EventFilter | string, listener: Listener): this;
  removeAllListeners(eventName: EventFilter | string): this;
  removeListener(eventName: any, listener: Listener): this;

  interface: IAvatarInterface;

  functions: {
    disableModule(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    "disableModule(address,address)"(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    enableModule(
      module: string,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    "enableModule(address)"(
      module: string,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    execTransactionFromModule(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    "execTransactionFromModule(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    execTransactionFromModuleReturnData(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<ContractTransaction>;

    getModulesPaginated(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      array: string[];
      next: string;
      0: string[];
      1: string;
    }>;

    "getModulesPaginated(address,uint256)"(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      array: string[];
      next: string;
      0: string[];
      1: string;
    }>;

    isModuleEnabled(
      module: string,
      overrides?: CallOverrides
    ): Promise<{
      0: boolean;
    }>;

    "isModuleEnabled(address)"(
      module: string,
      overrides?: CallOverrides
    ): Promise<{
      0: boolean;
    }>;
  };

  disableModule(
    prevModule: string,
    module: string,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  "disableModule(address,address)"(
    prevModule: string,
    module: string,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  enableModule(
    module: string,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  "enableModule(address)"(
    module: string,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  execTransactionFromModule(
    to: string,
    value: BigNumberish,
    data: BytesLike,
    operation: BigNumberish,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  "execTransactionFromModule(address,uint256,bytes,uint8)"(
    to: string,
    value: BigNumberish,
    data: BytesLike,
    operation: BigNumberish,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  execTransactionFromModuleReturnData(
    to: string,
    value: BigNumberish,
    data: BytesLike,
    operation: BigNumberish,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)"(
    to: string,
    value: BigNumberish,
    data: BytesLike,
    operation: BigNumberish,
    overrides?: Overrides
  ): Promise<ContractTransaction>;

  getModulesPaginated(
    start: string,
    pageSize: BigNumberish,
    overrides?: CallOverrides
  ): Promise<{
    array: string[];
    next: string;
    0: string[];
    1: string;
  }>;

  "getModulesPaginated(address,uint256)"(
    start: string,
    pageSize: BigNumberish,
    overrides?: CallOverrides
  ): Promise<{
    array: string[];
    next: string;
    0: string[];
    1: string;
  }>;

  isModuleEnabled(module: string, overrides?: CallOverrides): Promise<boolean>;

  "isModuleEnabled(address)"(
    module: string,
    overrides?: CallOverrides
  ): Promise<boolean>;

  callStatic: {
    disableModule(
      prevModule: string,
      module: string,
      overrides?: CallOverrides
    ): Promise<void>;

    "disableModule(address,address)"(
      prevModule: string,
      module: string,
      overrides?: CallOverrides
    ): Promise<void>;

    enableModule(module: string, overrides?: CallOverrides): Promise<void>;

    "enableModule(address)"(
      module: string,
      overrides?: CallOverrides
    ): Promise<void>;

    execTransactionFromModule(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    "execTransactionFromModule(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    execTransactionFromModuleReturnData(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      success: boolean;
      returnData: string;
      0: boolean;
      1: string;
    }>;

    "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      success: boolean;
      returnData: string;
      0: boolean;
      1: string;
    }>;

    getModulesPaginated(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      array: string[];
      next: string;
      0: string[];
      1: string;
    }>;

    "getModulesPaginated(address,uint256)"(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      array: string[];
      next: string;
      0: string[];
      1: string;
    }>;

    isModuleEnabled(
      module: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    "isModuleEnabled(address)"(
      module: string,
      overrides?: CallOverrides
    ): Promise<boolean>;
  };

  filters: {};

  estimateGas: {
    disableModule(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<BigNumber>;

    "disableModule(address,address)"(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<BigNumber>;

    enableModule(module: string, overrides?: Overrides): Promise<BigNumber>;

    "enableModule(address)"(
      module: string,
      overrides?: Overrides
    ): Promise<BigNumber>;

    execTransactionFromModule(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<BigNumber>;

    "execTransactionFromModule(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<BigNumber>;

    execTransactionFromModuleReturnData(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<BigNumber>;

    "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<BigNumber>;

    getModulesPaginated(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "getModulesPaginated(address,uint256)"(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isModuleEnabled(
      module: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    "isModuleEnabled(address)"(
      module: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    disableModule(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    "disableModule(address,address)"(
      prevModule: string,
      module: string,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    enableModule(
      module: string,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    "enableModule(address)"(
      module: string,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    execTransactionFromModule(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    "execTransactionFromModule(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    execTransactionFromModuleReturnData(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    "execTransactionFromModuleReturnData(address,uint256,bytes,uint8)"(
      to: string,
      value: BigNumberish,
      data: BytesLike,
      operation: BigNumberish,
      overrides?: Overrides
    ): Promise<PopulatedTransaction>;

    getModulesPaginated(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "getModulesPaginated(address,uint256)"(
      start: string,
      pageSize: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isModuleEnabled(
      module: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    "isModuleEnabled(address)"(
      module: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
