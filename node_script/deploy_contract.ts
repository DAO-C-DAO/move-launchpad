import { MoveBuilder } from "@initia/builder.js";
import * as fs from "fs";
import { getLcdClientAndWallet } from "./util";
import { MsgPublish } from "@initia/initia.js";

const run = async () => {
  const contractFolderPath = "contract";
  const contractName = "coin_launchpad";

  const { lcd, wallet2, wallet2Addr } = await getLcdClientAndWallet();

  const builder = new MoveBuilder(contractFolderPath, {
    skipFetchLatestGitDeps: true,
  });
  await builder.build();

  const codeBytes = fs.readFileSync(
    `../${contractFolderPath}/build/${contractName}/bytecode_modules/${contractName}.mv`
  );

  const deployContractMsg = new MsgPublish(
    wallet2Addr,
    [codeBytes.toString("base64")],
    1 // compatible
  );

  await wallet2
    .createAndSignTx({
      msgs: [deployContractMsg],
      memo: "deploy coin launchpad contract",
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
