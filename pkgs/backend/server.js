"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const web3_1 = __importDefault(require("web3"));
const Tickets_json_1 = __importDefault(require("../blockchain/build/contracts/Tickets.json"));
const fs_1 = __importDefault(require("fs"));
const address = "0x...CONTRACT_ADDRESS...";
const frontendPath = "../frontend/dist";
// レスポンスとして表示するhtml
const responseTemplate = fs_1.default.readFileSync("response.html").toString();
// ポート番号
const portNumber = 8080;
const providerUrl = "http://127.0.0.1:8545/"; //ここはブロックチェーンごとに変える。
const app = (0, express_1.default)();
app.use(express_1.default.static(frontendPath));
/**
 * login API
 */
app.get("/login", async (request, response) => {
    const message = request.query["msg"];
    const signature = request.query["sig"];
    const web3 = new web3_1.default(providerUrl);
    // @ts-ignore 型定義と厳密には一致しない
    const tickets = new web3.eth.Contract(Tickets_json_1.default.abi, address);
    try {
        // recover CEDSAの署名データとメッセージからアドレスを復元する。
        const signer = web3.eth.accounts.recover(`${message}`, `${signature}`);
        const balanceString = await tickets.methods.balanceOf(signer).call();
        const balance = web3.utils.toNumber(balanceString);
        if (balance == 0) {
            const body = responseTemplate.replace(/MESSAGE/, `
                <div class="alert alert-danger h2 m-4 text-center">
                    チケット トークンを確認できませんでした
                </div>`);
            response.status(401).send(body);
        }
        else {
            const body = responseTemplate.replace(/MESSAGE/, `
                <div class="alert alert-success h2 m-4 text-center">
                    <code class="h3">${signer}</code> さん、ようこそ！
                </div>`);
            response.status(200).send(body);
        }
    }
    catch (e) {
        const body = responseTemplate.replace(/MESSAGE/, `
            <div class="alert alert-danger h2 m-4 text-center">
                エラーが発生しました。<br>
                (${e})
            </div>`);
        response.status(500).send(body);
    }
});
app.listen(`${portNumber}`, () => {
    console.log(`http://localhost:${portNumber}/ で開始しました。`);
});
