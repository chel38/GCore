(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={"GC-IDENTITY-REGISTRATION-INVALID":`Проверьте адрес электронной почты.`,"GC-IDENTITY-EMAIL-TAKEN":`Этот адрес уже используется.`,"GC-IDENTITY-EMAIL-CODE-INVALID":`Неверный код подтверждения.`,"GC-IDENTITY-EMAIL-CODE-EXPIRED":`Код истёк. Запросите новый.`,"GC-IDENTITY-EMAIL-CODE-ATTEMPTS":`Лимит попыток исчерпан. Запросите новый код.`,"GC-IDENTITY-EMAIL-RESEND-COOLDOWN":`Новый код пока нельзя отправить. Дождитесь таймера.`,"GC-IDENTITY-MAIL-UNAVAILABLE":`Отправка email временно недоступна.`,"GC-IDENTITY-MAIL-TIMEOUT":`Почтовый сервис не ответил вовремя.`,"GC-IDENTITY-MAIL-SEND-FAILED":`Письмо не удалось отправить. Попробуйте позже.`,"GC-IDENTITY-ENDPOINT-UNAVAILABLE":`Сервер не смог безопасно определить сетевой адрес.`,"GC-IDENTITY-CHARACTER-INVALID":`Имя или фамилия имеют недопустимый формат.`,"GC-IDENTITY-CHARACTER-LIMIT":`Достигнут лимит персонажей.`,"GC-IDENTITY-CHARACTER-NOT-OWNED":`Персонаж не принадлежит вашему аккаунту.`,"GC-IDENTITY-RATE-LIMIT":`Слишком много запросов. Подождите немного.`,"GC-IDENTITY-DATABASE-UNAVAILABLE":`Сервис профилей временно недоступен.`,"GC-IDENTITY-DATABASE-QUERY-FAILED":`Не удалось получить профиль из базы данных.`,"GC-IDENTITY-CORE-UNAVAILABLE":`Игровое ядро временно недоступно.`,"GC-IDENTITY-HELLO-TIMEOUT":`Сервер не подтвердил состояние профиля вовремя.`,"GC-IDENTITY-NUI-NOT-READY":`Интерфейс профиля не смог запуститься.`,"GC-IDENTITY-CLIENT-REQUEST-PENDING":`Предыдущий запрос ещё выполняется.`,"GC-IDENTITY-NUI-TRANSPORT":`Не удалось связаться с игровым клиентом.`};function t(e){return e.replace(/[&<>'"]/g,e=>({"&":`&amp;`,"<":`&lt;`,">":`&gt;`,"'":`&#39;`,'"':`&quot;`})[e]??e)}function n(e){return`${e.firstName} ${e.lastName}`}function r(r,i){let a=null,o=null,s=null,c=!1,l=Date.now(),u=e=>Math.max(0,Math.ceil(e-(Date.now()-l)/1e3)),d=()=>`
    <section class="identity-shell" data-view="loading">
      <div class="panel panel--small text-center">
        <div class="brand-mark" aria-hidden="true">G</div>
        <p class="eyebrow">GCore Identity</p>
        <h1>Подготавливаем профиль</h1>
        <p class="muted">Проверяем аккаунт и доступных персонажей…</p>
        <div class="loader" role="status" aria-label="Загрузка"></div>
      </div>
    </section>`,f=()=>`<div class="alert" role="alert"><span>${t(e[s??``]??`Запрос отклонён. Повторите попытку.`)}</span><button data-action="dismiss-error" aria-label="Закрыть">×</button></div>`,p=()=>`
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
        ${m()}
      </section>`,m=()=>c?`
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
    </div>`:``,h=()=>`
    <section class="identity-shell" data-view="registration">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">Первый вход</p><h1>Создайте профиль</h1></div>
        </header>
        <p class="muted">Укажите email — мы отправим шестизначный код. Аккаунт будет создан только после подтверждения. Пароль не используется.</p>
        ${s?f():``}
        <form data-form="registration" novalidate>
          <label for="email">Электронная почта</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required placeholder="player@example.com" />
          <p class="field-note">Мы не запрашиваем пароль и не показываем license в интерфейсе.</p>
          <button class="button button--primary" type="submit" ${o?`disabled`:``}>
            ${o===`registerAccount`?`Отправляем…`:`Получить код`}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${m()}
    </section>`,g=()=>{let e=a?.verification;if(!e)return p();let n=e.type===`authentication`,r=u(e.resendIn);return`
      <section class="identity-shell" data-view="verification">
        <div class="panel panel--form">
          <header class="panel-header">
            <div class="brand-mark" aria-hidden="true">G</div>
            <div><p class="eyebrow">${n?`Безопасность входа`:`Подтверждение email`}</p><h1>${n?`Новый сетевой адрес`:`Проверьте почту`}</h1></div>
          </header>
          <p class="muted">Код отправлен на <strong>${t(e.maskedEmail)}</strong>. ${n?`Подтвердите вход с нового сетевого адреса.`:`Введите его, чтобы завершить регистрацию.`}</p>
          ${s?f():``}
          <form data-form="verification" novalidate>
            <label for="verificationCode">Шестизначный код</label>
            <input class="verification-code" id="verificationCode" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" pattern="[0-9]{6}" required placeholder="000000" />
            <p class="field-note">Код действует ещё <span data-expires-timer>${u(e.expiresIn)}</span> сек. Сервер проверяет срок и число попыток.</p>
            <button class="button button--primary" type="submit" ${o?`disabled`:``}>${o===`verifyEmail`?`Проверяем…`:`Подтвердить`}</button>
          </form>
          <button class="text-button" data-action="resend-verification" data-resend-button ${o||r>0?`disabled`:``}>
            ${r>0?`Отправить снова через <span data-resend-timer>${r}</span> сек.`:`Отправить новый код`}
          </button>
          <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
        </div>
        ${m()}
      </section>`},_=()=>{let e=a?.characters??[],r=a?.limits.maxCharacters??0,i=e.length<r,c=e.map(e=>`
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
          ${s?f():``}
          <div class="character-grid">${c||`<p class="empty-state">Персонажей пока нет. Создайте первого.</p>`}</div>
          <div class="divider"><span>${e.length} / ${r}</span></div>
          ${i?`
            <form class="create-form" data-form="character" novalidate>
              <div class="field"><label for="firstName">Имя</label><input id="firstName" name="firstName" maxlength="32" required /></div>
              <div class="field"><label for="lastName">Фамилия</label><input id="lastName" name="lastName" maxlength="32" required /></div>
              <button class="button button--secondary" type="submit" ${o?`disabled`:``}>${o===`createCharacter`?`Создаём…`:`Создать`}</button>
            </form>`:`<p class="field-note">Достигнут доступный лимит персонажей.</p>`}
        </div>
        ${m()}
      </section>`},v=()=>{r.innerHTML=a?[`uninitialized`,`loading`,`authorized`,`registering`,`character_selected`].includes(a.state)?d():a.state===`registration_required`?h():a.state===`email_verification_pending`||a.state===`auth_verification_required`?g():a.state===`character_required`?_():a.state===`error`?`<section class="identity-shell"><div class="panel panel--small text-center"><p class="eyebrow">Ошибка</p><h1>Профиль недоступен</h1>${f()}<button class="button button--secondary" data-action="refresh">Повторить</button></div></section>`:``:o===`refresh`?d():s?p():``,r.hidden=r.innerHTML.length===0},y=async(e,t)=>{if(o){s=`GC-IDENTITY-CLIENT-REQUEST-PENDING`,v();return}o=e,s=null,v();try{let n=await i.invoke(e.split(`:`)[0]??e,t);n.ok||(o=null,s=n.code??`GC-IDENTITY-REQUEST-REJECTED`,v())}catch{o=null,s=`GC-IDENTITY-NUI-TRANSPORT`,v()}},b=e=>{let t=e.target;if(!(t instanceof HTMLFormElement))return;e.preventDefault();let n=new FormData(t);t.dataset.form===`registration`?y(`registerAccount`,{email:String(n.get(`email`)??``).trim()}):t.dataset.form===`verification`?y(`verifyEmail`,{code:String(n.get(`code`)??``).trim()}):t.dataset.form===`character`&&y(`createCharacter`,{firstName:String(n.get(`firstName`)??``).trim(),lastName:String(n.get(`lastName`)??``).trim()})},x=e=>{let t=e.target instanceof Element?e.target.closest(`[data-action]`):null;if(!t)return;let n=t.dataset.action;if(n===`select-character`){let e=Number(t.dataset.characterId);y(`selectCharacter:${e}`,{characterId:e})}else n===`ask-exit`?(c=!0,v()):n===`cancel-exit`?(c=!1,v()):n===`confirm-exit`?y(`exit`,{}):n===`dismiss-error`?(s=null,v()):n===`refresh`?y(`refresh`,{}):n===`resend-verification`&&y(`resendVerification`,{})},S=e=>{e.key===`Escape`&&a?.state!==`ready`&&(c=!c,v())};r.addEventListener(`submit`,b),r.addEventListener(`click`,x),document.addEventListener(`keydown`,S),v();let C=window.setInterval(()=>{let e=a?.verification;if(!e)return;let t=r.querySelector(`[data-expires-timer]`);t&&(t.textContent=String(u(e.expiresIn)));let n=r.querySelector(`[data-resend-timer]`),i=r.querySelector(`[data-resend-button]`),s=u(e.resendIn);n&&(n.textContent=String(s)),i&&s===0&&!o&&(i.disabled=!1,i.textContent=`Отправить новый код`)},1e3);return{receive(e){e.type===`snapshot`?(a=e.payload,l=Date.now(),o=null,s=null,c=!1):e.type===`rejected`?(o=null,s=e.payload.code):e.type===`lifecycleError`?(a=null,o=null,s=e.payload.code):e.type===`reset`&&(a=null,o=null,s=null,c=!1),v()},destroy(){window.clearInterval(C),r.removeEventListener(`submit`,b),r.removeEventListener(`click`,x),document.removeEventListener(`keydown`,S)}}}function i(){return window.GetParentResourceName?.()??`gc_identity`}var a={async invoke(e,t){if(typeof window.GetParentResourceName!=`function`)return{ok:!0};let n=await fetch(`https://${i()}/${e}`,{method:`POST`,headers:{"Content-Type":`application/json; charset=UTF-8`},body:JSON.stringify(t)});return n.ok?await n.json():{ok:!1,code:`GC-IDENTITY-NUI-TRANSPORT`}}},o=document.querySelector(`#app`);if(!o)throw Error(`gc_identity NUI root is missing`);var s=r(o,a);window.addEventListener(`message`,e=>{(e.data?.type===`snapshot`||e.data?.type===`rejected`||e.data?.type===`lifecycleError`||e.data?.type===`reset`)&&s.receive(e.data)}),a.invoke(`ready`,{}).then(e=>{e.ok||s.receive({type:`lifecycleError`,payload:{code:e.code??`GC-IDENTITY-NUI-TRANSPORT`}})}).catch(()=>{s.receive({type:`lifecycleError`,payload:{code:`GC-IDENTITY-NUI-TRANSPORT`}})});