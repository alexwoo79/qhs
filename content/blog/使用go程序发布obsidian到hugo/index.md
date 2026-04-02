---
date: "2026-04-03T07:17:46+08:00"
draft: false
tags:
    - blog
    - go
    - hugo
title: 使用go程序发布obsidian到hugo
---


#blog #go #hugo

这是一个 **以 Obsidian 为唯一内容源** 的 Hugo 发布工具，使用 Go 编写。

它的目标不是“同步文件”，而是：

> **基于规则判断 → 生成 Hugo Page Bundle → 安全发布**

无需依赖 Obsidian 插件，不污染原始笔记，适合长期写作、博客与技术文档工作流。

---

## ✨ 核心特性

* 🧠 **单一内容源**：所有内容仅在 Obsidian 中维护

* 📦 **Hugo Page Bundle 原生支持**（`index.md` + 附件）

* 🏷 **基于 tag 的发布规则**（必须包含 `blog`）

* 🔍 **hash 级内容判断**：未变化内容自动跳过

* 🧪 **`--dry-run` 预演模式**：只提示，不写文件

* ♻️ **安全覆盖机制**：已存在内容提示是否更新
[使用Obsidian发布Hugo](../使用Obsidian发布Hugo_2/使用Obsidian发布Hugo.md)
---
## 📁 一、Obsidian 目录与写作规范（非常重要）

### 1️⃣ 每一篇 Blog 必须是一个独立文件夹


```text

ObsidianVault/

└── My First Blog/

├── My First Blog.md

├── image1.png

├── diagram.svg

```

  
* **文件夹 = 一篇文章（未来的 Hugo Page Bundle）**

* md 文件名可随意，但通常与文件夹名一致
---
### 2️⃣ 附件必须与 md 文件放在同一目录

* 图片 / PDF / SVG 等附件

* 不使用 Obsidian 的全局附件目录

这样才能：


* 直接 copy 到 Hugo Page Bundle

* 保证图片链接不失效

---
### 3️⃣ Obsidian 附件链接方式（必须修改）

请在 Obsidian 设置中调整：

```text

Settings → Files & Links → New link format

```

选择：

> ✅ **Markdown**

即生成：

```md

![](image1.png)

```

❌ 不要使用 `![[image1.png]]`（Wiki 链接）
---
### 4️⃣ 必须具备 `blog` 标签才会被发布


以下任一方式即可：

```md

#blog

```

或：

```yaml

tags:

- blog

- golang

- hugo

```


发布规则：

* ❌ 没有 `blog` → 不会进入 Hugo

* ✅ 有 `blog` → 发布

* ✅ 其他 tags 会 **完整映射到 Hugo front matter**


---
## 🏗 二、Hugo 侧要求

* 使用 **Page Bundle** 结构


```text

content/blog/my-first-blog/

├── index.md

├── image1.png

└── diagram.svg

```


* 本工具会：


* 自动将 md → `index.md`

* 自动补齐 Hugo front matter

---
## 🧩 三、Go 程序结构说明

```text

.

├── main.go # 程序入口，参数解析

├── config.go # config.json 读取

├── scan.go # 扫描 Obsidian 中可发布的 blog

├── publish.go # 发布决策（存在 / 覆盖 / dry-run）

├── hash.go # 目录级 hash 

├── config.json # 路径配置

```

---
### 🔁 发布流程（非常关键）

```text

Scan Obsidian

↓

检查是否包含 blog tag

↓

计算 Obsidian 目录 hash

↓

检查 Hugo 是否已存在 bundle

↓

┌───────────────┐

│ 内容未变化 │ → 跳过

├───────────────┤

│ 内容变化 │ → 提示是否覆盖

├───────────────┤

│ 不存在 │ → 发布

└───────────────┘

```

  


---
## 🧪 四、使用方式


### 1️⃣ 普通发布（安全模式）


```bash

go run .

```


* 已存在内容会询问是否覆盖

* 未变化内容自动跳过


---
### 2️⃣ dry-run（强烈推荐）


```bash

go run . --dry-run

```


输出示例：


```text

🆕 will publish: my-first-blog

⏭ unchanged: golang-notes

♻️ will overwrite: hugo-workflow

```


> ⚠️ 不会写入任何文件

---
### 3️⃣ 强制更新（CI / 批量发布）

```bash

go run . --update

```


* 不询问

* 直接覆盖

  

---
## 🧠 五、自动生成的 Hugo Front Matter

如果 Obsidian md 中没有定义，工具会自动补全：

```yaml

---

title: My First Blog

date: 2026-02-02T10:30:00+09:00

draft: false

tags:

- blog

- golang

---

```


已有字段 **不会被覆盖**。

---
## 🚀 六、适合谁使用？

  

* ✍️ 使用 Obsidian 写博客的人

* 🧠 希望 Hugo 内容完全可控的人

* 📚 技术文档 / 长期写作

* 🧩 Quarto / Pandoc / 多格式发布体系的前置工具


---
## 🏁 设计哲学

  

> **Obsidian 负责写作**

> **Go 工具负责决策与发布**

> **Hugo 只接收“干净内容”**


这个项目已经完全具备：


* 开源发布

* 团队写作

* CI 自动发布
---
