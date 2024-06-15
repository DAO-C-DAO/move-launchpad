import { MsgSend } from "@initia/initia.js";
import { getLcdClientAndWallet, CHAIN_DENOM } from "../util";

const run = async () => {
  const {
    lcd,
    wallet1,
    wallet2,
    wallet3,
    wallet1Addr,
    wallet2Addr,
    wallet3Addr,
  } = await getLcdClientAndWallet();

  const sendMsg = new MsgSend(wallet2Addr, wallet3Addr, {
    [CHAIN_DENOM]: 100_000,
  });

  await wallet2
    .createAndSignTx({
      msgs: [sendMsg],
      memo: "sample memo",
    })
    .then((signedTx) => {
      console.log("signedTx", signedTx);
      return lcd.tx.broadcast(signedTx);
    })
    .then((response) => {
      console.log("tx height", response.height, "tx hash", response.txhash);
    });
};

run();
