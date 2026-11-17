--[[
    候选黑名单：屏蔽指定的字/词，让它们不出现在候选列表里。

    为什么需要它：
      OpenCC 的部分字典是「一对多」映射，例如 STCharacters 中
          玩	玩 翫
      librime 的 simplifier 会把一个候选按 OpenCC 返回的所有写法展开成多个候选，
      所以「翫」不是按词频排上来的词条，而是「玩」被繁体化时额外生成的影子候选，
      永远紧跟在「玩」后面（玩第 2、翫第 3）。s2t / s2hk / s2tw 都受此影响。

    用法：
      1. 把要去掉的字/词写进下面的 blocked 表；
      2. 在该 schema 的 engine/filters 里加上：
             - lua_filter@*variant_denylist_filter
         放在 simplifier@transcription_cc 之后即可（本文件只删候选，不影响顺序）。

    注意：默认连反查（笔画/五笔/部件）出来的同一字也一并屏蔽。
          若只想拦截简繁转换产生的影子候选，把 only_converted 改成 true
          （此时候选类型必须是 simplified，词库里的原生词条与反查结果都不受影响）。
--]]

-- 要屏蔽的字/词（键为候选文本，值为 true）
local blocked = {
    ["翫"] = true,  -- 玩 → 玩/翫（OpenCC 一对多转换带出来的异体字）
}

-- true: 只拦截 OpenCC 转换产生的影子候选；false: 出现在任何候选里都拦截
local only_converted = false

local function variant_denylist_filter(input, env)
    for cand in input:iter() do
        local drop = blocked[cand.text]
        if drop and only_converted and cand.type ~= "simplified" then
            drop = false
        end
        if not drop then
            yield(cand)
        end
    end
end

return variant_denylist_filter
