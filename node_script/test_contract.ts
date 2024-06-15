import { MoveBuilder } from "@initia/builder.js";

const run = async () => {
  const contractFolderPath = "contract";

  const builder = new MoveBuilder(contractFolderPath, {
    skipFetchLatestGitDeps: true,
    testMode: true,
    devMode: true,
  });
  await builder.test();
};

run();
