(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={"GC-IDENTITY-REGISTRATION-INVALID":{ru:`Укажите имя, фамилию латиницей и корректный email.`,en:`Enter a Latin first and last name and a valid email.`},"GC-IDENTITY-REGISTRATION-NAME-INVALID":{ru:`Имя и фамилия должны состоять только из латинских букв.`,en:`First and last name may contain Latin letters only.`},"GC-IDENTITY-NAME-INVALID":{ru:`Имя и фамилия должны состоять только из латинских букв.`,en:`First and last name may contain Latin letters only.`},"GC-IDENTITY-REGISTRATION-NOT-VERIFIED":{ru:`Сначала подтвердите адрес электронной почты.`,en:`Verify the email address first.`},"GC-IDENTITY-REGISTRATION-CHANGED":{ru:`Данные регистрации изменились. Запросите новый код.`,en:`Registration details changed. Request a new code.`},"GC-IDENTITY-SPAWN-MODE-MISCONFIGURED":{ru:`Сервер не включил безопасный pre-spawn режим.`,en:`The server did not enable secure pre-spawn mode.`},"GC-IDENTITY-EMAIL-TAKEN":{ru:`Эта почта уже используется.`,en:`This email is already in use.`},"GC-IDENTITY-EMAIL-CODE-INVALID":{ru:`Неверный код подтверждения.`,en:`The verification code is invalid.`},"GC-IDENTITY-EMAIL-CODE-EXPIRED":{ru:`Код истёк. Запросите новый.`,en:`The code expired. Request a new one.`},"GC-IDENTITY-EMAIL-CODE-ATTEMPTS":{ru:`Лимит попыток исчерпан. Запросите новый код.`,en:`The attempt limit was reached. Request a new code.`},"GC-IDENTITY-EMAIL-RESEND-COOLDOWN":{ru:`Новый код пока нельзя отправить. Дождитесь таймера.`,en:`Please wait before requesting another code.`},"GC-IDENTITY-MAIL-UNAVAILABLE":{ru:`Отправка email временно недоступна.`,en:`Email delivery is temporarily unavailable.`},"GC-IDENTITY-MAIL-TIMEOUT":{ru:`Почтовый сервис не ответил вовремя.`,en:`The mail service did not respond in time.`},"GC-IDENTITY-MAIL-SEND-FAILED":{ru:`Письмо не удалось отправить. Попробуйте позже.`,en:`The email could not be sent. Try again later.`},"GC-IDENTITY-ENDPOINT-UNAVAILABLE":{ru:`Сервер не смог безопасно определить сетевой адрес.`,en:`The server could not securely resolve the network address.`},"GC-IDENTITY-CHARACTER-INVALID":{ru:`Имя или фамилия имеют недопустимый формат.`,en:`The first or last name has an invalid format.`},"GC-IDENTITY-CHARACTER-LIMIT":{ru:`Достигнут лимит персонажей.`,en:`The character limit has been reached.`},"GC-IDENTITY-CHARACTER-NOT-OWNED":{ru:`Персонаж не принадлежит вашему аккаунту.`,en:`The character does not belong to your account.`},"GC-IDENTITY-RATE-LIMIT":{ru:`Слишком много запросов. Подождите немного.`,en:`Too many requests. Please wait a moment.`},"GC-IDENTITY-DATABASE-UNAVAILABLE":{ru:`Сервис профилей временно недоступен.`,en:`The identity service is temporarily unavailable.`},"GC-IDENTITY-DATABASE-QUERY-FAILED":{ru:`Не удалось получить профиль из базы данных.`,en:`The profile could not be loaded from the database.`},"GC-IDENTITY-CORE-UNAVAILABLE":{ru:`Игровое ядро временно недоступно.`,en:`The game core is temporarily unavailable.`},"GC-IDENTITY-HELLO-TIMEOUT":{ru:`Сервер не подтвердил состояние профиля вовремя.`,en:`The server did not confirm identity state in time.`},"GC-IDENTITY-NUI-NOT-READY":{ru:`Интерфейс профиля не смог запуститься.`,en:`The identity interface failed to start.`},"GC-IDENTITY-CLIENT-REQUEST-PENDING":{ru:`Предыдущий запрос ещё выполняется.`,en:`The previous request is still running.`},"GC-IDENTITY-NUI-TRANSPORT":{ru:`Не удалось связаться с игровым клиентом.`,en:`The interface could not reach the game client.`}};function t(e){return e.replace(/[&<>'"]/g,e=>({"&":`&amp;`,"<":`&lt;`,">":`&gt;`,"'":`&#39;`,'"':`&quot;`})[e]??e)}function n(e){return`${e.firstName} ${e.lastName}`}function r(r,i){let a=null,o=null,s=null,c=!1,l=Date.now(),u=`hidden`,d=null,f=null,p={fullName:``,email:``},m=(e,t)=>a?.locale===`en`?t:e,h=e=>Math.max(0,Math.ceil(e-(Date.now()-l)/1e3)),g=()=>{d!==null&&(window.clearTimeout(d),d=null)},_=()=>{g(),f!==null&&(window.cancelAnimationFrame(f),f=null),r.innerHTML=``,r.hidden=!0,r.classList.remove(`identity-root--active`),r.removeAttribute(`data-view`),r.setAttribute(`aria-hidden`,`true`),u=`hidden`},v=()=>{let t=e[s??``];return t?a?.locale===`en`?t.en:t.ru:m(`Запрос отклонён. Повторите попытку.`,`The request was rejected. Try again.`)},y=()=>`
    <div class="alert" role="alert">
      <span>${t(v())}</span>
      <button data-action="dismiss-error" aria-label="${m(`Закрыть ошибку`,`Dismiss error`)}">×</button>
    </div>`,b=()=>c?`
    <div class="modal-backdrop" role="presentation">
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="exit-title">
        <p class="eyebrow">${m(`Выход`,`Exit`)}</p>
        <h2 id="exit-title">${m(`Покинуть сервер?`,`Leave the server?`)}</h2>
        <p class="muted">${m(`Текущие сохранённые данные не будут потеряны.`,`Your saved data will not be lost.`)}</p>
        <div class="actions actions--split">
          <button class="button button--ghost" data-action="cancel-exit">${m(`Остаться`,`Stay`)}</button>
          <button class="button button--danger" data-action="confirm-exit">${m(`Выйти`,`Exit`)}</button>
        </div>
      </section>
    </div>`:``,x=(e,t)=>`
    <section class="identity-shell" data-shell-view="${e}" aria-label="GCore Identity">
      <div class="identity-background" aria-hidden="true">
        <div class="identity-background__grid"></div>
        <div class="identity-background__glow identity-background__glow--left"></div>
        <div class="identity-background__glow identity-background__glow--right"></div>
      </div>
      <div class="identity-layout">
        <header class="shell-brand" aria-label="GCore">
          <span class="brand-mark" aria-hidden="true">G</span>
          <span><strong>GCore</strong><small>Identity</small></span>
        </header>
        <main class="identity-content">${t}</main>
        <footer class="shell-footer">${m(`Безопасная авторизация GCore`,`Secure GCore authorization`)}</footer>
      </div>
      ${b()}
    </section>`,S=()=>{if(g(),u!==`registration-verification`&&u!==`login-verification`)return;let e=()=>{if(u!==`registration-verification`&&u!==`login-verification`){g();return}let t=a?.verification;if(!t){g();return}let n=r.querySelector(`[data-expires-timer]`);n&&(n.textContent=String(h(t.expiresIn)));let i=h(t.resendIn),s=r.querySelector(`[data-resend-timer]`),c=r.querySelector(`[data-resend-button]`);s&&(s.textContent=String(i)),c&&i===0&&!o&&(c.disabled=!1,c.textContent=m(`Отправить новый код`,`Send a new code`)),d=window.setTimeout(e,1e3)};d=window.setTimeout(e,1e3)},C=(e,t)=>{_(),r.innerHTML=x(e,t),r.hidden=!1,r.classList.add(`identity-root--active`),r.dataset.view=e,r.setAttribute(`aria-hidden`,`false`),u=e,S(),f=window.requestAnimationFrame(()=>{f=null,u===e&&!r.hidden&&i.invoke(`presented`,{view:e})})},w=()=>`
    <article class="panel panel--small text-center">
      <p class="eyebrow">GCore Identity</p>
      <h1>${m(`Подготавливаем профиль`,`Preparing your profile`)}</h1>
      <p class="muted">${m(`Проверяем состояние аккаунта…`,`Checking your account state…`)}</p>
      <div class="loader" role="status" aria-label="${m(`Загрузка`,`Loading`)}"></div>
    </article>`,T=()=>`
    <article class="panel panel--small text-center" aria-busy="true">
      <div class="success-mark" aria-hidden="true">✓</div>
      <p class="eyebrow">GCore</p>
      <h1>${m(`Входим на сервер…`,`Entering the server…`)}</h1>
      <p class="muted">${m(`Подготавливаем игровой мир. Экран откроется после подтверждения spawn сервером.`,`Preparing the game world. The screen opens after the server confirms spawn.`)}</p>
      <div class="loader" role="status" aria-label="${m(`Spawn выполняется`,`Spawn in progress`)}"></div>
    </article>`,E=()=>`
    <article class="panel panel--small text-center">
      <p class="eyebrow">GCore Identity</p>
      <h1>${m(`Профиль недоступен`,`Profile unavailable`)}</h1>
      <p class="muted" role="alert">${t(v())}</p>
      <p class="diagnostic-code">${t(s??`GC-IDENTITY-UNKNOWN`)}</p>
      <div class="actions actions--split">
        <button class="button button--secondary" data-action="refresh">${m(`Повторить`,`Retry`)}</button>
        <button class="button button--danger" data-action="ask-exit">${m(`Выйти`,`Exit`)}</button>
      </div>
    </article>`,D=()=>`
    <article class="panel panel--form">
      <header class="panel-header">
        <div><p class="eyebrow">${m(`Первый вход`,`First visit`)}</p><h1>${m(`Регистрация`,`Registration`)}</h1></div>
      </header>
      <p class="muted">${m(`Создайте профиль GCore перед первым входом.`,`Create your GCore profile before entering the server.`)}</p>
      <form data-form="registration" novalidate>
        <div class="field">
          <label for="fullName">${m(`Имя Фамилия`,`First name Last name`)}</label>
          <input id="fullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${t(p.fullName)}" />
          <p class="field-note">${m(`Введите имя и фамилию английскими буквами через пробел.`,`Enter your first and last name in Latin letters, separated by a space.`)}</p>
        </div>
        <div class="field">
          <label for="email">${m(`Электронная почта`,`Email`)}</label>
          <input id="email" name="email" type="email" autocomplete="email" spellcheck="false" maxlength="254" required placeholder="user@example.com" value="${t(p.email)}" />
          <p class="field-note">${m(`На эту почту будет отправлен шестизначный код подтверждения.`,`A six-digit verification code will be sent to this address.`)}</p>
        </div>
        ${s?y():``}
        <button class="button button--primary" type="submit" ${o?`disabled`:``}>
          ${o===`sendRegistrationCode`?m(`Отправляем…`,`Sending…`):m(`Отправить код`,`Send code`)}
        </button>
      </form>
      <button class="text-button text-button--quiet" data-action="ask-exit">${m(`Выйти с сервера`,`Leave the server`)}</button>
    </article>`,O=()=>{let e=a?.verification;if(!e)return E();let n=e.type===`authentication`,r=h(e.resendIn);return`
      <article class="panel panel--form">
        <header class="panel-header">
          <div>
            <p class="eyebrow">${n?m(`Безопасность входа`,`Login security`):m(`Регистрация`,`Registration`)}</p>
            <h1>${n?m(`Подтверждение входа`,`Login verification`):m(`Проверьте почту`,`Check your inbox`)}</h1>
          </div>
        </header>
        <p class="muted">${n?m(`Мы обнаружили вход с нового сетевого адреса. Код необходим для безопасного продолжения.`,`We detected a login from a new network address. The code is required to continue securely.`):m(`Код отправлен на указанную почту. Подтверждение ещё не создаёт аккаунт — после него останется финальный шаг.`,`The code was sent to your email. Verification does not create the account yet; one final step remains.`)}</p>
        <div class="masked-email"><span>${m(`Код отправлен на`,`Code sent to`)}</span><strong>${t(e.maskedEmail)}</strong></div>
        <form data-form="verification" novalidate>
          <label for="verificationCode">${m(`Код подтверждения`,`Verification code`)}</label>
          <input class="verification-code" id="verificationCode" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" pattern="[0-9]{6}" required placeholder="000000" aria-describedby="verification-help" />
          <p class="field-note" id="verification-help">${m(`Код действует ещё`,`Code expires in`)} <span data-expires-timer>${h(e.expiresIn)}</span> ${m(`сек.`,`sec.`)}</p>
          ${s?y():``}
          <button class="button button--primary" type="submit" ${o?`disabled`:``}>
            ${o===`verifyEmail`?m(`Проверяем…`,`Verifying…`):m(`Подтвердить код`,`Verify code`)}
          </button>
        </form>
        <button class="text-button" data-action="resend-verification" data-resend-button ${o||r>0?`disabled`:``}>
          ${r>0?`${m(`Отправить повторно через`,`Send again in`)} <span data-resend-timer>${r}</span> ${m(`сек.`,`sec.`)}`:m(`Отправить новый код`,`Send a new code`)}
        </button>
        ${n?``:`<button class="text-button text-button--secondary" data-action="change-registration-email">${m(`Изменить email`,`Change email`)}</button>`}
        <button class="text-button text-button--quiet" data-action="ask-exit">${m(`Выйти с сервера`,`Leave the server`)}</button>
      </article>`},k=()=>{let e=a?.registration;return e?.emailVerified?`
      <article class="panel panel--form text-center">
        <div class="success-mark" aria-hidden="true">✓</div>
        <p class="eyebrow">${m(`Email подтверждён`,`Email verified`)}</p>
        <h1>${m(`Завершите регистрацию`,`Finish registration`)}</h1>
        <dl class="profile-summary">
          <div><dt>${m(`Имя`,`Name`)}</dt><dd>${t(e.fullName)}</dd></div>
          <div><dt>Email</dt><dd>${t(e.email)}</dd></div>
        </dl>
        ${s?y():``}
        <button class="button button--primary" data-action="finalize-registration" ${o?`disabled`:``}>
          ${o===`finalizeRegistration`?m(`Завершаем…`,`Finishing…`):m(`Завершить регистрацию`,`Finish registration`)}
        </button>
        <button class="text-button text-button--secondary" data-action="change-registration-email">${m(`Изменить email`,`Change email`)}</button>
        <button class="text-button text-button--quiet" data-action="ask-exit">${m(`Выйти с сервера`,`Leave the server`)}</button>
      </article>`:E()},A=()=>`
    <article class="panel panel--form">
      <header class="panel-header"><div><p class="eyebrow">${m(`Обновление профиля`,`Profile update`)}</p><h1>${m(`Регистрация`,`Registration`)}</h1></div></header>
      <p class="muted">${m(`У существующего аккаунта ещё нет зарегистрированного имени. Укажите имя и фамилию до spawn.`,`This existing account has no registered name yet. Enter your first and last name before spawn.`)}</p>
      <form data-form="profile" novalidate>
        <label for="profileFullName">${m(`Имя Фамилия`,`First name Last name`)}</label>
        <input id="profileFullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${t(p.fullName)}" />
        <p class="field-note">${m(`Введите имя и фамилию английскими буквами через пробел.`,`Enter your first and last name in Latin letters, separated by a space.`)}</p>
        ${s?y():``}
        <button class="button button--primary" type="submit" ${o?`disabled`:``}>
          ${o===`completeProfile`?m(`Сохраняем…`,`Saving…`):m(`Сохранить и продолжить`,`Save and continue`)}
        </button>
      </form>
      <button class="text-button text-button--quiet" data-action="ask-exit">${m(`Выйти с сервера`,`Leave the server`)}</button>
    </article>`,j=()=>{let e=a?.characters??[],r=a?.limits.maxCharacters??0,i=e.length<r,c=e.map(e=>`
      <article class="character-card">
        <div class="avatar" aria-hidden="true">${t(e.firstName.charAt(0).toUpperCase())}</div>
        <div class="character-copy"><h3>${t(n(e))}</h3><p>ID ${e.id}</p></div>
        <button class="button button--primary button--compact" data-action="select-character" data-character-id="${e.id}" ${o?`disabled`:``}>
          ${o===`select:${e.id}`?m(`Выбираем…`,`Selecting…`):m(`Играть`,`Play`)}
        </button>
      </article>`).join(``);return`
      <article class="panel panel--wide">
        <header class="panel-header panel-header--spread">
          <div><p class="eyebrow">${m(`Аккаунт`,`Account`)} ${t(a?.account?.email??``)}</p><h1>${m(`Выберите персонажа`,`Choose a character`)}</h1></div>
          <button class="icon-button" data-action="ask-exit" aria-label="${m(`Выйти`,`Exit`)}">↗</button>
        </header>
        ${s?y():``}
        <div class="character-grid">${c||`<p class="empty-state">${m(`Персонажей пока нет. Создайте первого.`,`There are no characters yet. Create your first one.`)}</p>`}</div>
        <div class="divider"><span>${e.length} / ${r}</span></div>
        ${i?`
          <form class="create-form" data-form="character" novalidate>
            <div class="field"><label for="firstName">${m(`Имя`,`First name`)}</label><input id="firstName" name="firstName" maxlength="32" required /></div>
            <div class="field"><label for="lastName">${m(`Фамилия`,`Last name`)}</label><input id="lastName" name="lastName" maxlength="32" required /></div>
            <button class="button button--secondary" type="submit" ${o?`disabled`:``}>${o===`createCharacter`?m(`Создаём…`,`Creating…`):m(`Создать`,`Create`)}</button>
          </form>`:`<p class="field-note">${m(`Достигнут доступный лимит персонажей.`,`The available character limit has been reached.`)}</p>`}
      </article>`},M=()=>{if(!a)return o===`refresh`?`loading`:s?`fatal-error`:`hidden`;switch(a.state){case`uninitialized`:case`loading`:case`registering`:return`loading`;case`registration_required`:return`registration`;case`email_verification_pending`:return`registration-verification`;case`auth_verification_required`:return`login-verification`;case`registration_verified`:return`registration-verified`;case`profile_completion_required`:return`profile-completion`;case`authorized`:case`registration_finalizing`:case`spawn_releasing`:case`post_spawn_identity`:case`character_selected`:return`spawn-transition`;case`character_required`:return`characters`;case`error`:return`fatal-error`;case`ready`:case`disconnecting`:return`hidden`;default:return s=`GC-IDENTITY-NUI-UNKNOWN-VIEW`,`fatal-error`}},N=()=>{let e=M();if(e===`hidden`){_();return}e===`loading`?C(e,w()):e===`registration`?C(e,D()):e===`registration-verification`||e===`login-verification`?C(e,O()):e===`registration-verified`?C(e,k()):e===`profile-completion`?C(e,A()):e===`spawn-transition`?C(e,T()):e===`characters`?C(e,j()):C(`fatal-error`,E())},P=async(e,t,n=!0)=>{if(o){s=`GC-IDENTITY-CLIENT-REQUEST-PENDING`,N();return}o=e,s=null,n&&N();try{let n=await i.invoke(e.split(`:`)[0]??e,t);n.ok||(o=null,s=n.code??`GC-IDENTITY-REQUEST-REJECTED`,N())}catch{o=null,s=`GC-IDENTITY-NUI-TRANSPORT`,N()}},F=e=>{let t=e.target;if(!(t instanceof HTMLFormElement))return;e.preventDefault();let n=new FormData(t);if(t.dataset.form===`registration`)p={fullName:String(n.get(`fullName`)??``).trim(),email:String(n.get(`email`)??``).trim()},P(`sendRegistrationCode`,p);else if(t.dataset.form===`verification`){let e=String(n.get(`code`)??``).replace(/\D/g,``).slice(0,6);P(`verifyEmail`,{code:e})}else t.dataset.form===`profile`?(p.fullName=String(n.get(`fullName`)??``).trim(),P(`completeProfile`,{fullName:p.fullName})):t.dataset.form===`character`&&P(`createCharacter`,{firstName:String(n.get(`firstName`)??``).trim(),lastName:String(n.get(`lastName`)??``).trim()})},I=e=>{let t=e.target;!(t instanceof HTMLInputElement)||t.id!==`verificationCode`||(t.value=t.value.replace(/\D/g,``).slice(0,6))},L=e=>{let t=e.target instanceof Element?e.target.closest(`[data-action]`):null;if(!t)return;let n=t.dataset.action;if(n===`select-character`){let e=Number(t.dataset.characterId);P(`selectCharacter:${e}`,{characterId:e})}else n===`ask-exit`?(c=!0,N()):n===`cancel-exit`?(c=!1,N()):n===`confirm-exit`?(_(),P(`exit`,{},!1)):n===`dismiss-error`?(s=null,N()):n===`refresh`?P(`refresh`,{}):n===`resend-verification`?P(`resendVerification`,{}):n===`change-registration-email`?P(`changeRegistrationEmail`,{}):n===`finalize-registration`&&P(`finalizeRegistration`,{})},R=e=>{e.key===`Escape`&&u!==`hidden`&&(c=!c,N())};return r.addEventListener(`submit`,F),r.addEventListener(`input`,I),r.addEventListener(`click`,L),document.addEventListener(`keydown`,R),_(),{receive(e){e.type===`snapshot`?(a=e.payload,l=Date.now(),o=null,s=null,c=!1,e.payload.registration&&(p={fullName:e.payload.registration.fullName,email:e.payload.registration.email})):e.type===`rejected`?(o=null,s=e.payload.code):e.type===`lifecycleError`?(a=null,o=null,s=e.payload.code):e.type===`reset`&&(a=null,o=null,s=null,c=!1,p={fullName:``,email:``}),N()},destroy(){_(),r.removeEventListener(`submit`,F),r.removeEventListener(`input`,I),r.removeEventListener(`click`,L),document.removeEventListener(`keydown`,R)}}}function i(){return window.GetParentResourceName?.()??`gc_identity`}var a={async invoke(e,t){if(typeof window.GetParentResourceName!=`function`)return{ok:!0};let n=await fetch(`https://${i()}/${e}`,{method:`POST`,headers:{"Content-Type":`application/json; charset=UTF-8`},body:JSON.stringify(t)});return n.ok?await n.json():{ok:!1,code:`GC-IDENTITY-NUI-TRANSPORT`}}},o=document.querySelector(`#app`);if(!o)throw Error(`gc_identity NUI root is missing`);var s=r(o,a);window.addEventListener(`message`,e=>{(e.data?.type===`snapshot`||e.data?.type===`rejected`||e.data?.type===`lifecycleError`||e.data?.type===`reset`)&&s.receive(e.data)}),a.invoke(`ready`,{}).then(e=>{e.ok||s.receive({type:`lifecycleError`,payload:{code:e.code??`GC-IDENTITY-NUI-TRANSPORT`}})}).catch(()=>{s.receive({type:`lifecycleError`,payload:{code:`GC-IDENTITY-NUI-TRANSPORT`}})});