(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={"GC-IDENTITY-REGISTRATION-INVALID":`Проверьте адрес электронной почты.`,"GC-IDENTITY-EMAIL-TAKEN":`Этот адрес уже используется.`,"GC-IDENTITY-CHARACTER-INVALID":`Имя или фамилия имеют недопустимый формат.`,"GC-IDENTITY-CHARACTER-LIMIT":`Достигнут лимит персонажей.`,"GC-IDENTITY-CHARACTER-NOT-OWNED":`Персонаж не принадлежит вашему аккаунту.`,"GC-IDENTITY-RATE-LIMIT":`Слишком много запросов. Подождите немного.`,"GC-IDENTITY-DATABASE-UNAVAILABLE":`Сервис профилей временно недоступен.`,"GC-IDENTITY-DATABASE-QUERY-FAILED":`Не удалось получить профиль из базы данных.`,"GC-IDENTITY-CORE-UNAVAILABLE":`Игровое ядро временно недоступно.`,"GC-IDENTITY-HELLO-TIMEOUT":`Сервер не подтвердил состояние профиля вовремя.`,"GC-IDENTITY-NUI-NOT-READY":`Интерфейс профиля не смог запуститься.`,"GC-IDENTITY-CLIENT-REQUEST-PENDING":`Предыдущий запрос ещё выполняется.`,"GC-IDENTITY-NUI-TRANSPORT":`Не удалось связаться с игровым клиентом.`};function t(e){return e.replace(/[&<>'"]/g,e=>({"&":`&amp;`,"<":`&lt;`,">":`&gt;`,"'":`&#39;`,'"':`&quot;`})[e]??e)}function n(e){return`${e.firstName} ${e.lastName}`}function r(r,i){let a=null,o=null,s=null,c=!1,l=()=>`
    <section class="identity-shell" data-view="loading">
      <div class="panel panel--small text-center">
        <div class="brand-mark" aria-hidden="true">G</div>
        <p class="eyebrow">GCore Identity</p>
        <h1>Подготавливаем профиль</h1>
        <p class="muted">Проверяем аккаунт и доступных персонажей…</p>
        <div class="loader" role="status" aria-label="Загрузка"></div>
      </div>
    </section>`,u=()=>`<div class="alert" role="alert"><span>${t(e[s??``]??`Запрос отклонён. Повторите попытку.`)}</span><button data-action="dismiss-error" aria-label="Закрыть">×</button></div>`,d=()=>`
      <section class="identity-shell" data-view="lifecycle-error">
        <div class="panel panel--small text-center">
          <p class="eyebrow">GCore Identity</p>
          <h1>Профиль недоступен</h1>
          <p class="muted" role="alert">${t(e[s??``]??`Не удалось подготовить профиль.`)}</p>
          <p class="diagnostic-code">${t(s??`GC-IDENTITY-UNKNOWN`)}</p>
          <div class="actions actions--split">
            <button class="button button--secondary" data-action="refresh">Повторить</button>
            <button class="button button--danger" data-action="ask-exit">Выйти</button>
          </div>
        </div>
        ${f()}
      </section>`,f=()=>c?`
    <div class="modal-backdrop" role="presentation">
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="exit-title">
        <p class="eyebrow">Выход</p>
        <h2 id="exit-title">Покинуть сервер?</h2>
        <p class="muted">Текущие сохранённые данные не будут потеряны.</p>
        <div class="actions actions--split">
          <button class="button button--ghost" data-action="cancel-exit">Остаться</button>
          <button class="button button--danger" data-action="confirm-exit">Выйти</button>
        </div>
      </section>
    </div>`:``,p=()=>`
    <section class="identity-shell" data-view="registration">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">Первый вход</p><h1>Создайте профиль</h1></div>
        </header>
        <p class="muted">Ваш FiveM license уже подтверждает вход. Email нужен для уникального игрового профиля; пароль на этом этапе не используется.</p>
        ${s?u():``}
        <form data-form="registration" novalidate>
          <label for="email">Электронная почта</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required placeholder="player@example.com" />
          <p class="field-note">Мы не запрашиваем пароль и не показываем license в интерфейсе.</p>
          <button class="button button--primary" type="submit" ${o?`disabled`:``}>
            ${o===`registerAccount`?`Создаём…`:`Продолжить`}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${f()}
    </section>`,m=()=>{let e=a?.characters??[],r=a?.limits.maxCharacters??0,i=e.length<r,c=e.map(e=>`
      <article class="character-card">
        <div class="avatar" aria-hidden="true">${t(e.firstName.charAt(0).toUpperCase())}</div>
        <div class="character-copy">
          <h3>${t(n(e))}</h3>
          <p>ID ${e.id}</p>
        </div>
        <button class="button button--primary button--compact" data-action="select-character" data-character-id="${e.id}" ${o?`disabled`:``}>
          ${o===`select:${e.id}`?`Выбираем…`:`Играть`}
        </button>
      </article>`).join(``);return`
      <section class="identity-shell" data-view="characters">
        <div class="panel panel--wide">
          <header class="panel-header panel-header--spread">
            <div><p class="eyebrow">Аккаунт ${t(a?.account?.email??``)}</p><h1>Выберите персонажа</h1></div>
            <button class="icon-button" data-action="ask-exit" aria-label="Выйти">↗</button>
          </header>
          ${s?u():``}
          <div class="character-grid">${c||`<p class="empty-state">Персонажей пока нет. Создайте первого.</p>`}</div>
          <div class="divider"><span>${e.length} / ${r}</span></div>
          ${i?`
            <form class="create-form" data-form="character" novalidate>
              <div class="field"><label for="firstName">Имя</label><input id="firstName" name="firstName" maxlength="32" required /></div>
              <div class="field"><label for="lastName">Фамилия</label><input id="lastName" name="lastName" maxlength="32" required /></div>
              <button class="button button--secondary" type="submit" ${o?`disabled`:``}>${o===`createCharacter`?`Создаём…`:`Создать`}</button>
            </form>`:`<p class="field-note">Достигнут доступный лимит персонажей.</p>`}
        </div>
        ${f()}
      </section>`},h=()=>{r.innerHTML=a?[`uninitialized`,`loading`,`authorized`,`registering`,`character_selected`].includes(a.state)?l():a.state===`registration_required`?p():a.state===`character_required`?m():a.state===`error`?`<section class="identity-shell"><div class="panel panel--small text-center"><p class="eyebrow">Ошибка</p><h1>Профиль недоступен</h1>${u()}<button class="button button--secondary" data-action="refresh">Повторить</button></div></section>`:``:o===`refresh`?l():s?d():``,r.hidden=r.innerHTML.length===0},g=async(e,t)=>{if(o){s=`GC-IDENTITY-CLIENT-REQUEST-PENDING`,h();return}o=e,s=null,h();try{let n=await i.invoke(e.split(`:`)[0]??e,t);n.ok||(o=null,s=n.code??`GC-IDENTITY-REQUEST-REJECTED`,h())}catch{o=null,s=`GC-IDENTITY-NUI-TRANSPORT`,h()}},_=e=>{let t=e.target;if(!(t instanceof HTMLFormElement))return;e.preventDefault();let n=new FormData(t);t.dataset.form===`registration`?g(`registerAccount`,{email:String(n.get(`email`)??``).trim()}):t.dataset.form===`character`&&g(`createCharacter`,{firstName:String(n.get(`firstName`)??``).trim(),lastName:String(n.get(`lastName`)??``).trim()})},v=e=>{let t=e.target instanceof Element?e.target.closest(`[data-action]`):null;if(!t)return;let n=t.dataset.action;if(n===`select-character`){let e=Number(t.dataset.characterId);g(`selectCharacter:${e}`,{characterId:e})}else n===`ask-exit`?(c=!0,h()):n===`cancel-exit`?(c=!1,h()):n===`confirm-exit`?g(`exit`,{}):n===`dismiss-error`?(s=null,h()):n===`refresh`&&g(`refresh`,{})},y=e=>{e.key===`Escape`&&a?.state!==`ready`&&(c=!c,h())};return r.addEventListener(`submit`,_),r.addEventListener(`click`,v),document.addEventListener(`keydown`,y),h(),{receive(e){e.type===`snapshot`?(a=e.payload,o=null,s=null,c=!1):e.type===`rejected`?(o=null,s=e.payload.code):e.type===`lifecycleError`?(a=null,o=null,s=e.payload.code):e.type===`reset`&&(a=null,o=null,s=null,c=!1),h()},destroy(){r.removeEventListener(`submit`,_),r.removeEventListener(`click`,v),document.removeEventListener(`keydown`,y)}}}function i(){return window.GetParentResourceName?.()??`gc_identity`}var a={async invoke(e,t){if(typeof window.GetParentResourceName!=`function`)return{ok:!0};let n=await fetch(`https://${i()}/${e}`,{method:`POST`,headers:{"Content-Type":`application/json; charset=UTF-8`},body:JSON.stringify(t)});return n.ok?await n.json():{ok:!1,code:`GC-IDENTITY-NUI-TRANSPORT`}}},o=document.querySelector(`#app`);if(!o)throw Error(`gc_identity NUI root is missing`);var s=r(o,a);window.addEventListener(`message`,e=>{(e.data?.type===`snapshot`||e.data?.type===`rejected`||e.data?.type===`lifecycleError`||e.data?.type===`reset`)&&s.receive(e.data)}),a.invoke(`ready`,{}).then(e=>{e.ok||s.receive({type:`lifecycleError`,payload:{code:e.code??`GC-IDENTITY-NUI-TRANSPORT`}})}).catch(()=>{s.receive({type:`lifecycleError`,payload:{code:`GC-IDENTITY-NUI-TRANSPORT`}})});