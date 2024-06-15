import { MsgExecute, bcs } from "@initia/initia.js";
import { getLcdClientAndWallet } from "../util";

const run = async () => {
  const { lcd, wallet2, wallet2Addr } = await getLcdClientAndWallet();

  const maxSupply = 1_000;
  const decimals = 6;

  const executeMsg = new MsgExecute(
    wallet2Addr,
    wallet2Addr,
    "coin_launchpad",
    "create_coin",
    [],
    [
      bcs
        .u64()
        .serialize(maxSupply * Math.pow(10, decimals))
        .toBase64(),
      bcs.string().serialize("Test Coin").toBase64(),
      bcs.string().serialize("TC").toBase64(),
      bcs.u8().serialize(decimals).toBase64(),
      bcs.string().serialize("icon_uri").toBase64(),
      bcs.string().serialize("project_uri").toBase64(),
    ]
  );

  await wallet2
    .createAndSignTx({
      msgs: [executeMsg],
      memo: "create a coin",
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
