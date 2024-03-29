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
  PayableOverrides,
  CallOverrides,
} from "@ethersproject/contracts";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";

interface IShamanInterface extends ethers.utils.Interface {
  functions: {
    "memberAction(address,uint96,uint96)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "memberAction",
    values: [string, BigNumberish, BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "memberAction",
    data: BytesLike
  ): Result;

  events: {};
}

export class IShaman extends Contract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  on(event: EventFilter | string, listener: Listener): this;
  once(event: EventFilter | string, listener: Listener): this;
  addListener(eventName: EventFilter | string, listener: Listener): this;
  removeAllListeners(eventName: EventFilter | string): this;
  removeListener(eventName: any, listener: Listener): this;

  interface: IShamanInterface;

  functions: {
    memberAction(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<ContractTransaction>;

    "memberAction(address,uint96,uint96)"(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<ContractTransaction>;
  };

  memberAction(
    member: string,
    loot: BigNumberish,
    shares: BigNumberish,
    overrides?: PayableOverrides
  ): Promise<ContractTransaction>;

  "memberAction(address,uint96,uint96)"(
    member: string,
    loot: BigNumberish,
    shares: BigNumberish,
    overrides?: PayableOverrides
  ): Promise<ContractTransaction>;

  callStatic: {
    memberAction(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      lootOut: BigNumber;
      sharesOut: BigNumber;
      0: BigNumber;
      1: BigNumber;
    }>;

    "memberAction(address,uint96,uint96)"(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: CallOverrides
    ): Promise<{
      lootOut: BigNumber;
      sharesOut: BigNumber;
      0: BigNumber;
      1: BigNumber;
    }>;
  };

  filters: {};

  estimateGas: {
    memberAction(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<BigNumber>;

    "memberAction(address,uint96,uint96)"(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    memberAction(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<PopulatedTransaction>;

    "memberAction(address,uint96,uint96)"(
      member: string,
      loot: BigNumberish,
      shares: BigNumberish,
      overrides?: PayableOverrides
    ): Promise<PopulatedTransaction>;
  };
}
