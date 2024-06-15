import { getLcdClientAndWallet, printAxiosError } from "../util";

const run = async () => {
  const { lcd, wallet1, wallet2, wallet1Addr, wallet2Addr } =
    await getLcdClientAndWallet();
  const wallet1Balances = await lcd.bank.balance(wallet1Addr);
  console.log(
    `Balance of ${wallet1Addr}: ${JSON.stringify(wallet1Balances, null, 2)}`
  );

  const wallet2Balances = await lcd.bank.balance(wallet2Addr);
  console.log(
    `Balance of ${wallet2Addr}: ${JSON.stringify(wallet2Balances, null, 2)}`
  );
};

run();
