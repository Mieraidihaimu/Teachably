import Foundation

extension Skill {
    /// Search vocabulary is separate from display copy so a short translated
    /// title does not have to include every common way to ask about an interest.
    func searchAliases(language: AppLanguage) -> String {
        [title(language: language), Self.searchVocabulary[.english]?[self] ?? "",
         Self.searchVocabulary[language]?[self] ?? ""].joined(separator: " ")
    }

    private static let searchVocabulary: [AppLanguage: [Skill: String]] = [
        .english: [
            .numbers: "math maths mathematics counting quantity numbers money patterns",
            .reading: "read reading books words literacy letters pictures",
            .movement: "movement exercise sport balance coordination",
            .science: "science physics light sound gravity motion shadows vibrations ramp",
            .journaling: "diary writing journal journaling reflection memory memories feelings",
            .coding: "coding programming code algorithms sequences loop loops debugging instructions robot",
            .criticalThinking: "critical thinking reasoning evidence clues questions guesses decisions",
            .making: "making fixing building design craft repair",
            .nature: "nature outdoors plants trees leaves animals",
            .cooking: "cooking kitchen food recipes quantities",
            .music: "music rhythm sound singing beat",
            .storytelling: "stories storytelling imagination characters pretend"
        ],
        .simplifiedChinese: [
            .numbers: "数学 数字 数数 计数 数量 钱 图案 规律",
            .reading: "阅读 读书 图书 书本 识字 绘本 文字",
            .movement: "运动 锻炼 活动 体操 平衡 身体 协调",
            .science: "科学 物理 光 声音 重力 影子 振动 斜坡",
            .journaling: "日记 写作 记录 记忆 回忆 感受",
            .coding: "编程 代码 逻辑 程序 算法 顺序 循环 调试 机器人",
            .criticalThinking: "批判性思维 思考 推理 证据 线索 问题 猜测 判断 决策",
            .making: "制作 修理 搭建 建造 设计 手工",
            .nature: "自然 户外 植物 树木 树叶 动物",
            .cooking: "烹饪 做饭 厨房 食物 食谱 份量",
            .music: "音乐 节奏 声音 唱歌 节拍",
            .storytelling: "故事 讲故事 想象 角色 扮演"
        ],
        .traditionalChinese: [
            .numbers: "數學 數字 數數 計數 數量 錢 圖案 規律",
            .reading: "閱讀 讀書 圖書 書本 識字 繪本 文字",
            .movement: "運動 鍛鍊 活動 體操 平衡 身體 協調",
            .science: "科學 物理 光 聲音 重力 影子 振動 斜坡",
            .journaling: "日記 寫作 記錄 記憶 回憶 感受",
            .coding: "程式設計 編程 程式碼 邏輯 演算法 順序 迴圈 除錯 機器人",
            .criticalThinking: "批判性思考 思考 推理 證據 線索 問題 猜測 判斷 決策",
            .making: "製作 修理 搭建 建造 設計 手作",
            .nature: "自然 戶外 植物 樹木 樹葉 動物",
            .cooking: "烹飪 做飯 廚房 食物 食譜 份量",
            .music: "音樂 節奏 聲音 唱歌 節拍",
            .storytelling: "故事 說故事 想像 角色 扮演"
        ],
        .japanese: [
            .numbers: "算数 数学 数字 数える 計算 お金 模様 パターン",
            .reading: "読書 読む 本 読み聞かせ 絵本 文字 言葉",
            .movement: "運動 体操 動く スポーツ バランス 体 身体",
            .science: "科学 物理 光 音 重力 影 振動 坂",
            .journaling: "日記 書く 記録 思い出 気持ち 振り返り",
            .coding: "プログラミング コード 論理 手順 順番 繰り返し ループ デバッグ ロボット",
            .criticalThinking: "考える 思考 推論 根拠 証拠 手がかり 問い 予想 判断",
            .making: "工作 作る 直す 修理 組み立て 設計",
            .nature: "自然 屋外 植物 木 葉っぱ 動物",
            .cooking: "料理 台所 食べ物 レシピ 分量",
            .music: "音楽 リズム 音 歌 拍子",
            .storytelling: "物語 お話 想像 登場人物 ごっこ遊び"
        ],
        .spanish: [
            .numbers: "matemáticas números contar cantidad dinero patrones",
            .reading: "lectura leer libros palabras letras cuentos",
            .movement: "movimiento ejercicio deporte gimnasia equilibrio coordinación",
            .science: "ciencia física luz sonido gravedad sombras vibraciones rampa",
            .journaling: "diario escribir escritura recuerdos memoria emociones reflexión",
            .coding: "programación código lógica algoritmos secuencias bucles depuración instrucciones robot",
            .criticalThinking: "pensamiento crítico razonar razonamiento pruebas evidencia pistas preguntas decisiones",
            .making: "construir crear reparar manualidades diseño arreglar",
            .nature: "naturaleza aire libre plantas árboles hojas animales",
            .cooking: "cocina cocinar comida recetas cantidades",
            .music: "música ritmo sonidos cantar compás",
            .storytelling: "historias cuentos imaginación personajes narración inventar"
        ],
        .indonesian: [
            .numbers: "matematika angka menghitung jumlah pola uang",
            .reading: "membaca bacaan buku huruf kata literasi",
            .movement: "gerak gerakan olahraga senam bergerak keseimbangan koordinasi",
            .science: "sains fisika cahaya suara gravitasi bayangan getaran lereng",
            .journaling: "diari jurnal menulis catatan kenangan ingatan perasaan refleksi",
            .coding: "pemrograman kode logika algoritma urutan pengulangan perulangan debug instruksi robot",
            .criticalThinking: "berpikir kritis penalaran bukti petunjuk pertanyaan dugaan keputusan",
            .making: "membuat memperbaiki membangun kerajinan desain",
            .nature: "alam luar ruangan tumbuhan pohon daun hewan",
            .cooking: "memasak dapur makanan resep takaran",
            .music: "musik irama ritme bunyi bernyanyi ketukan",
            .storytelling: "cerita bercerita dongeng imajinasi tokoh bermain peran"
        ]
    ]
}
