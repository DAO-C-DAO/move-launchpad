import "dotenv/config";
import { env } from "process";
import axios from "axios";
import { Wallet, LCDClient, MnemonicKey } from "@initia/initia.js";

export const RPC_ENDPOINT: string = env.RPC_ENDPOINT!;
export const LCD_ENDPOINT: string = env.LCD_ENDPOINT!;

export const CHAIN_ID: string = env.CHAIN_ID!;
export const CHAIN_PREFIX: string = env.CHAIN_PREFIX!;
export const CHAIN_DENOM: string = env.CHAIN_DENOM!;

export const GAS_SYMBOL =
  "move/944f8dd8dc49f96c25fea9849f16436dcfa6d564eec802f3ef7f8b3ea85368ff";

export const getLcdClientAndWallet = async () => {
  const key1 = new MnemonicKey({ mnemonic: env.MNEMONIC_1! });
  const key2 = new MnemonicKey({ mnemonic: env.MNEMONIC_2! });
  const key3 = new MnemonicKey({ mnemonic: env.MNEMONIC_3! });

  const lcd = new LCDClient(LCD_ENDPOINT, {
    chainId: CHAIN_ID,
    // gasPrices: "0.25uinit", // default gas prices
    gasPrices: `0.15${GAS_SYMBOL}`,
    gasAdjustment: "1.5", // default gas adjustment for fee estimation
  });
  const wallet1 = new Wallet(lcd, key1);
  const wallet2 = new Wallet(lcd, key2);
  const wallet3 = new Wallet(lcd, key3);

  return {
    lcd,
    wallet1,
    wallet2,
    wallet3,
    wallet1Addr: wallet1.key.accAddress,
    wallet2Addr: wallet2.key.accAddress,
    wallet3Addr: wallet3.key.accAddress,
  };
};

// if is axios error then print the extracted part otherwise print whole error
// most of time it should be cause axios error is the one returned when we call lcd
export const printAxiosError = (e: any) => {
  if (axios.isAxiosError(e)) {
    if (e.response) {
      console.log(e.response.status);
      console.log(e.response.headers);
      if (
        typeof e.response.data === "object" &&
        e.response.data !== null &&
        "code" in e.response.data &&
        "message" in e.response.data
      ) {
        console.log(
          `Code=${e.response?.data["code"]} Message=${e.response?.data["message"]} \n`
        );
      } else {
        console.log(e.response.data);
      }
    }
  } else {
    console.log(e);
  }
};
