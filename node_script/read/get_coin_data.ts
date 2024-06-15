import { bcs } from "@initia/initia.js";
import { getLcdClientAndWallet, printAxiosError } from "../util";

const run = async () => {
  const { lcd, wallet2Addr } = await getLcdClientAndWallet();
  const resp = await lcd.move.view(
    wallet2Addr,
    "coin_launchpad",
    "get_coin_data",
    [],
    [
      bcs
        .object()
        .serialize(
          "0xd77b91d81a4c4e0d86244eeb74a5ea2ff13c6079126c6bad01911817ea63ae12"
        )
        .toBase64(),
    ]
  );
  console.log(`Coin data: ${JSON.stringify(resp, null, 2)}`);
};

run();
