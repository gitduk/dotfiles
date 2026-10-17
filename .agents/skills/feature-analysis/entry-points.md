# 入口定位速查

按"功能是被什么触发的"分类。先判断形态,再用对应的搜索式。搜索一律带 `-n` 输出行号,便于直接引用。

## 目录

- [通用搜索阶梯](#通用搜索阶梯)
- [HTTP 接口](#http-接口)
- [前端交互](#前端交互)
- [CLI 命令](#cli-命令)
- [异步任务与队列](#异步任务与队列)
- [定时任务](#定时任务)
- [事件与消息](#事件与消息)
- [数据库侧触发](#数据库侧触发)
- [找不到入口时](#找不到入口时)

---

## 通用搜索阶梯

```bash
# 1. 用户可见字符串(最可靠)
rg -n "导出报表|Export report" --type-add 'web:*.{ts,tsx,vue}' 

# 2. 错误信息反查
rg -n "库存不足"

# 3. 表名/字段名反查写入方
rg -n "\borders\b" --glob '!*.sql'

# 4. 测试文件当活文档
fd -t f 'test.*order|order.*test'

# 5. git 历史找引入点
git log --oneline --grep "订单导出"
git log -S "create_order" --oneline    # 找函数首次出现的提交
git log -p -1 <commit> -- path/to/file  # 看那次改了什么
```

---

## HTTP 接口

| 框架 | 搜索式 |
|---|---|
| FastAPI | `rg -n '@(app\|router)\.(get\|post\|put\|patch\|delete)'` |
| Flask | `rg -n '@.*\.route\('` 或 `add_url_rule` |
| Django | 从 `urls.py` 开始,`rg -n 'path\(\|re_path\('` |
| Express | `rg -n 'router\.(get\|post)\|app\.(get\|post)'` |
| Axum | `rg -n 'Router::new\|\.route\('` |
| Actix | `rg -n '#\[(get\|post\|put\|delete)\('` |
| Gin | `rg -n '\.(GET\|POST\|PUT\|DELETE)\('` |
| Spring | `rg -n '@(Get\|Post\|Put\|Delete\|Request)Mapping'` |
| Next.js | `app/**/route.ts` 或 `pages/api/**`,文件路径即 URL |

**中间件不能漏。** 认证、限流、事务、日志常常挂在路由之外(FastAPI 的 `Depends`、Axum 的 `layer`、Express 的 `use`)。它们会在请求到达 handler 之前改变数据或直接短路,属于主链路的一部分。搜 `rg -n 'Depends\(|\.layer\(|app\.use\('`。

---

## 前端交互

从用户看到的东西倒推:

1. **文案 → 组件**:`rg -n "提交订单"`。如果用了 i18n,先在语言包里找到 key,再用 key 搜组件。
2. **组件 → handler**:在组件里找 `onClick` / `@click` / `onSubmit` 绑定的函数。
3. **handler → 网络请求**:找 `fetch` / `axios` / `useMutation` / RPC client 调用,拿到 URL 或方法名。
4. **URL → 后端路由**:回到上一节。

注意状态管理层(Redux/Zustand/Pinia/React Query)常常把请求和组件解耦,链路会经过一个 store 或 hook,不要在组件里找不到请求就断定"前端没调后端"。

---

## CLI 命令

| 生态 | 搜索式 |
|---|---|
| Python argparse | `rg -n 'add_parser\|add_argument'` |
| Python click/typer | `rg -n '@(click\|app)\.command'` |
| Rust clap | `rg -n '#\[derive\(.*Parser\|#\[command'` |
| Go cobra | `rg -n 'cobra\.Command\{'` |
| Node | `package.json` 的 `bin` 字段 + commander 的 `.command(` |

也别忘了 `pyproject.toml` / `Cargo.toml` / `package.json` 里声明的可执行入口,那是真正的 `main`。

---

## 异步任务与队列

| 形态 | 搜索式 |
|---|---|
| Celery | `rg -n '@(shared_task\|app\.task\|celery\.task)'`,再搜 `.delay(` / `.apply_async(` 找投递方 |
| RQ | `rg -n 'queue\.enqueue'` |
| Sidekiq | `rg -n 'include Sidekiq::Worker'` |
| BullMQ | `rg -n 'new Worker\(|\.add\('` |
| Kafka/RabbitMQ 消费者 | `rg -n 'consume\|subscribe\|@KafkaListener'` |
| tokio | `rg -n 'tokio::spawn'` |

**关键**:异步任务一定要同时找到**投递方**和**消费方**,这两处通常在不同文件,而任务参数的序列化格式就是它们之间的隐式契约 —— 也是最容易出不一致的地方,值得在数据结构章节单列。

---

## 定时任务

- 应用内:`rg -n 'APScheduler\|@scheduled\|cron_job\|schedule\.every'`
- 系统级:`crontab -l`、`/etc/cron.d/`、systemd timer(`systemctl list-timers`)
- 编排层:k8s `CronJob` YAML、GitHub Actions `schedule:`、云厂商定时触发器
- 框架内置:Django management command + 外部调度、Rails `rake` 任务

定时入口经常散落在代码库之外(基础设施仓库、控制台配置),搜不到时直接问用户。

---

## 事件与消息

- **Webhook 接收**:本质是 HTTP 入口,但通常有签名校验中间件,注意它。
- **应用内事件总线**:`rg -n 'emit\(|dispatch\(|publish\(|on\('`。事件名是字符串字面量,拿事件名再搜订阅方。
- **WebSocket**:`rg -n 'websocket\|socket\.on\|@sio\.event'`,按消息 type 字段分发的话,搜 type 值。
- **信号机制**:Django signals(`rg -n '@receiver'`)、Rails callbacks(`after_create` 等)。这类"隐式触发"极易被忽略,一旦存在必须写进报告 —— 它们是"改了 A 结果 B 炸了"的主要来源。

---

## 数据库侧触发

触发器、存储过程、物化视图刷新、CDC(Debezium 等)。在迁移文件里搜 `rg -n 'CREATE TRIGGER|CREATE FUNCTION'`。这类逻辑不在应用代码里,读代码永远读不到,但它确实是链路的一环。

---

## 找不到入口时

按顺序试:

1. **放宽关键词**。中文界面搜中文,英文界面搜英文,再试拼音缩写和字段名。
2. **从输出倒推**。功能产生了什么可观测的东西(一条日志、一行数据、一个文件、一封邮件)?搜那个东西的生成处,向上回溯调用方(`rg -n 'func_name\('`)。
3. **看运行时**。如果能跑起来,加日志或看现有日志的 request id 串联;有 APM/tracing 就直接看一条 trace,这比静态搜索准得多。
4. **问用户**。让用户描述一次具体操作(点了哪个按钮、跑了什么命令、看到什么结果),或者直接给一个已知相关的文件当种子。这不是失败,盲猜才是。
