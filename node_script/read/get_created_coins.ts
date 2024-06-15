import { bcs } from "@initia/initia.js";
import { getLcdClientAndWallet, printAxiosError } from "../util";

const run = async () => {
  const { lcd, wallet2Addr } = await getLcdClientAndWallet();
  const resp = await lcd.move.view(
    wallet2Addr,
    "coin_launchpad",
    "get_created_coins",
    [],
    [
      bcs.option(bcs.string()).serialize(undefined).toBase64(),
      bcs.option(bcs.u64()).serialize(undefined).toBase64(),
    ]
  );
  console.log(`Created coins: ${JSON.stringify(resp, null, 2)}`);
};

run();
