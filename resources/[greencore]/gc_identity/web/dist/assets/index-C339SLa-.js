(function(){let e=document.createElement(`link`).relList;if(e&&e.supports&&e.supports(`modulepreload`))return;for(let e of document.querySelectorAll(`link[rel="modulepreload"]`))n(e);new MutationObserver(e=>{for(let t of e)if(t.type===`childList`)for(let e of t.addedNodes)e.tagName===`LINK`&&e.rel===`modulepreload`&&n(e)}).observe(document,{childList:!0,subtree:!0});function t(e){let t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),t.credentials=e.crossOrigin===`use-credentials`?`include`:e.crossOrigin===`anonymous`?`omit`:`same-origin`,t}function n(e){if(e.ep)return;e.ep=!0;let n=t(e);fetch(e.href,n)}})();var e={"GC-IDENTITY-REGISTRATION-INVALID":`Укажите имя, фамилию латиницей и корректный email.`,"GC-IDENTITY-REGISTRATION-NAME-INVALID":`Имя и фамилия должны состоять только из латинских букв.`,"GC-IDENTITY-NAME-INVALID":`Имя и фамилия должны состоять только из латинских букв.`,"GC-IDENTITY-REGISTRATION-NOT-VERIFIED":`Сначала подтвердите адрес электронной почты.`,"GC-IDENTITY-REGISTRATION-CHANGED":`Данные регистрации изменились. Запросите новый код.`,"GC-IDENTITY-SPAWN-MODE-MISCONFIGURED":`Сервер не включил безопасный pre-spawn режим.`,"GC-IDENTITY-EMAIL-TAKEN":`Этот адрес уже используется.`,"GC-IDENTITY-EMAIL-CODE-INVALID":`Неверный код подтверждения.`,"GC-IDENTITY-EMAIL-CODE-EXPIRED":`Код истёк. Запросите новый.`,"GC-IDENTITY-EMAIL-CODE-ATTEMPTS":`Лимит попыток исчерпан. Запросите новый код.`,"GC-IDENTITY-EMAIL-RESEND-COOLDOWN":`Новый код пока нельзя отправить. Дождитесь таймера.`,"GC-IDENTITY-MAIL-UNAVAILABLE":`Отправка email временно недоступна.`,"GC-IDENTITY-MAIL-TIMEOUT":`Почтовый сервис не ответил вовремя.`,"GC-IDENTITY-MAIL-SEND-FAILED":`Письмо не удалось отправить. Попробуйте позже.`,"GC-IDENTITY-ENDPOINT-UNAVAILABLE":`Сервер не смог безопасно определить сетевой адрес.`,"GC-IDENTITY-CHARACTER-INVALID":`Имя или фамилия имеют недопустимый формат.`,"GC-IDENTITY-CHARACTER-LIMIT":`Достигнут лимит персонажей.`,"GC-IDENTITY-CHARACTER-NOT-OWNED":`Персонаж не принадлежит вашему аккаунту.`,"GC-IDENTITY-RATE-LIMIT":`Слишком много запросов. Подождите немного.`,"GC-IDENTITY-DATABASE-UNAVAILABLE":`Сервис профилей временно недоступен.`,"GC-IDENTITY-DATABASE-QUERY-FAILED":`Не удалось получить профиль из базы данных.`,"GC-IDENTITY-CORE-UNAVAILABLE":`Игровое ядро временно недоступно.`,"GC-IDENTITY-HELLO-TIMEOUT":`Сервер не подтвердил состояние профиля вовремя.`,"GC-IDENTITY-NUI-NOT-READY":`Интерфейс профиля не смог запуститься.`,"GC-IDENTITY-CLIENT-REQUEST-PENDING":`Предыдущий запрос ещё выполняется.`,"GC-IDENTITY-NUI-TRANSPORT":`Не удалось связаться с игровым клиентом.`},t={"GC-IDENTITY-REGISTRATION-INVALID":`Enter a Latin first and last name and a valid email.`,"GC-IDENTITY-NAME-INVALID":`First and last name may contain Latin letters only.`,"GC-IDENTITY-EMAIL-TAKEN":`This email is already in use.`,"GC-IDENTITY-EMAIL-CODE-INVALID":`The verification code is invalid.`,"GC-IDENTITY-EMAIL-CODE-EXPIRED":`The code expired. Request a new one.`,"GC-IDENTITY-EMAIL-CODE-ATTEMPTS":`The attempt limit was reached. Request a new code.`,"GC-IDENTITY-EMAIL-RESEND-COOLDOWN":`Please wait before requesting another code.`,"GC-IDENTITY-MAIL-UNAVAILABLE":`Email delivery is temporarily unavailable.`,"GC-IDENTITY-MAIL-TIMEOUT":`The mail service did not respond in time.`,"GC-IDENTITY-DATABASE-UNAVAILABLE":`The identity service is temporarily unavailable.`,"GC-IDENTITY-CORE-UNAVAILABLE":`The game core is temporarily unavailable.`,"GC-IDENTITY-SPAWN-MODE-MISCONFIGURED":`The server did not enable secure pre-spawn mode.`,"GC-IDENTITY-HELLO-TIMEOUT":`The server did not confirm identity state in time.`,"GC-IDENTITY-NUI-NOT-READY":`The identity interface failed to start.`,"GC-IDENTITY-CLIENT-REQUEST-PENDING":`The previous request is still running.`,"GC-IDENTITY-NUI-TRANSPORT":`The interface could not reach the game client.`};function n(e){return e.replace(/[&<>'"]/g,e=>({"&":`&amp;`,"<":`&lt;`,">":`&gt;`,"'":`&#39;`,'"':`&quot;`})[e]??e)}function r(e){return`${e.firstName} ${e.lastName}`}function i(i,a){let o=null,s=null,c=null,l=!1,u=Date.now(),d=(e,t)=>o?.locale===`en`?t:e,f=e=>Math.max(0,Math.ceil(e-(Date.now()-u)/1e3)),p=()=>`
    <section class="identity-shell" data-view="loading">
      <div class="panel panel--small text-center">
        <div class="brand-mark" aria-hidden="true">G</div>
        <p class="eyebrow">GCore Identity</p>
        <h1>${d(`Подготавливаем профиль`,`Preparing your profile`)}</h1>
        <p class="muted">${d(`Проверяем аккаунт и доступных персонажей…`,`Checking your account and available characters…`)}</p>
        <div class="loader" role="status" aria-label="${d(`Загрузка`,`Loading`)}"></div>
      </div>
    </section>`,m=()=>`<div class="alert" role="alert"><span>${n((o?.locale===`en`?t:e)[c??``]??d(`Запрос отклонён. Повторите попытку.`,`The request was rejected. Try again.`))}</span><button data-action="dismiss-error" aria-label="Закрыть">×</button></div>`,h=()=>`
      <section class="identity-shell" data-view="lifecycle-error">
        <div class="panel panel--small text-center">
          <p class="eyebrow">GCore Identity</p>
          <h1>Профиль недоступен</h1>
          <p class="muted" role="alert">${n((o?.locale===`en`?t:e)[c??``]??d(`Не удалось подготовить профиль.`,`The profile could not be prepared.`))}</p>
          <p class="diagnostic-code">${n(c??`GC-IDENTITY-UNKNOWN`)}</p>
          <div class="actions actions--split">
            <button class="button button--secondary" data-action="refresh">Повторить</button>
            <button class="button button--danger" data-action="ask-exit">Выйти</button>
          </div>
        </div>
        ${g()}
      </section>`,g=()=>l?`
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
    </div>`:``,_=()=>{let e=o?.registration;return`
    <section class="identity-shell" data-view="registration">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">${d(`Первый вход`,`First visit`)}</p><h1>${d(`Регистрация`,`Registration`)}</h1></div>
        </header>
        <p class="muted">${d(`Укажите имя и фамилию латиницей, затем email. Аккаунт и spawn будут разрешены только после подтверждения и финального шага.`,`Enter a Latin first and last name, then email. The account and spawn are allowed only after verification and finalization.`)}</p>
        ${c?m():``}
        <form data-form="registration" novalidate>
          <label for="fullName">${d(`Имя Фамилия`,`First name Last name`)}</label>
          <input id="fullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" value="${n(e?.fullName??``)}" />
          <label for="email">${d(`Электронная почта`,`Email`)}</label>
          <input id="email" name="email" type="email" autocomplete="email" maxlength="254" required placeholder="player@example.com" value="${n(e?.email??``)}" />
          <p class="field-note">${d(`Мы не запрашиваем пароль и не показываем license в интерфейсе.`,`We do not request a password or expose your license in the UI.`)}</p>
          <button class="button button--primary" type="submit" ${s?`disabled`:``}>
            ${s===`sendRegistrationCode`?d(`Отправляем…`,`Sending…`):d(`Отправить код`,`Send code`)}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${g()}
    </section>`},v=()=>{let e=o?.verification;if(!e)return h();let t=e.type===`authentication`,r=f(e.resendIn);return`
      <section class="identity-shell" data-view="verification">
        <div class="panel panel--form">
          <header class="panel-header">
            <div class="brand-mark" aria-hidden="true">G</div>
            <div><p class="eyebrow">${t?d(`Безопасность входа`,`Login security`):d(`Подтверждение email`,`Email verification`)}</p><h1>${t?d(`Новый сетевой адрес`,`New network address`):d(`Проверьте почту`,`Check your inbox`)}</h1></div>
          </header>
          <p class="muted">${d(`Код отправлен на`,`A code was sent to`)} <strong>${n(e.maskedEmail)}</strong>. ${t?d(`Подтвердите вход с нового сетевого адреса.`,`Confirm login from the new network address.`):d(`Проверка кода ещё не создаёт аккаунт и не разрешает spawn.`,`Code verification does not create the account or allow spawn yet.`)}</p>
          ${c?m():``}
          <form data-form="verification" novalidate>
            <label for="verificationCode">${d(`Шестизначный код`,`Six-digit code`)}</label>
            <input class="verification-code" id="verificationCode" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" minlength="6" maxlength="6" pattern="[0-9]{6}" required placeholder="000000" />
            <p class="field-note">${d(`Код действует ещё`,`Code expires in`)} <span data-expires-timer>${f(e.expiresIn)}</span> ${d(`сек. Сервер проверяет срок и число попыток.`,`sec. The server checks expiry and attempts.`)}</p>
            <button class="button button--primary" type="submit" ${s?`disabled`:``}>${s===`verifyEmail`?d(`Проверяем…`,`Verifying…`):d(`Подтвердить`,`Verify`)}</button>
          </form>
          <button class="text-button" data-action="resend-verification" data-resend-button ${s||r>0?`disabled`:``}>
            ${r>0?`${d(`Отправить снова через`,`Send again in`)} <span data-resend-timer>${r}</span> ${d(`сек.`,`sec.`)}`:d(`Отправить новый код`,`Send a new code`)}
          </button>
          ${t?``:`<button class="text-button" data-action="change-registration-email">${d(`Изменить email`,`Change email`)}</button>`}
          <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
        </div>
        ${g()}
      </section>`},y=()=>{let e=o?.registration;return e?.emailVerified?`
      <section class="identity-shell" data-view="registration-verified">
        <div class="panel panel--form text-center">
          <div class="brand-mark" aria-hidden="true">G</div>
          <p class="eyebrow">${d(`Email подтверждён`,`Email verified`)}</p>
          <h1>${d(`Завершите регистрацию`,`Finish registration`)}</h1>
          <p class="muted"><strong>${n(e.fullName)}</strong><br />${n(e.email)}</p>
          <p class="field-note">${d(`Только этот шаг атомарно создаст аккаунт и разрешит серверу запросить spawn.`,`Only this step atomically creates the account and lets the server request spawn.`)}</p>
          ${c?m():``}
          <button class="button button--primary" data-action="finalize-registration" ${s?`disabled`:``}>
            ${s===`finalizeRegistration`?d(`Завершаем…`,`Finishing…`):d(`Завершить регистрацию`,`Finish registration`)}
          </button>
          <button class="text-button" data-action="change-registration-email">${d(`Изменить email`,`Change email`)}</button>
          <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
        </div>
        ${g()}
      </section>`:h()},b=()=>`
    <section class="identity-shell" data-view="profile-completion">
      <div class="panel panel--form">
        <header class="panel-header">
          <div class="brand-mark" aria-hidden="true">G</div>
          <div><p class="eyebrow">${d(`Обновление профиля`,`Profile update`)}</p><h1>${d(`Регистрация`,`Registration`)}</h1></div>
        </header>
        <p class="muted">${d(`У этого существующего аккаунта ещё нет зарегистрированного имени. Укажите имя и фамилию латиницей до spawn.`,`This existing account has no registered name yet. Enter a Latin first and last name before spawn.`)}</p>
        ${c?m():``}
        <form data-form="profile" novalidate>
          <label for="profileFullName">${d(`Имя Фамилия`,`First name Last name`)}</label>
          <input id="profileFullName" name="fullName" type="text" autocomplete="name" minlength="5" maxlength="65" pattern="[A-Za-z]+ [A-Za-z]+" required placeholder="John Smith" />
          <button class="button button--primary" type="submit" ${s?`disabled`:``}>
            ${s===`completeProfile`?d(`Сохраняем…`,`Saving…`):d(`Сохранить и продолжить`,`Save and continue`)}
          </button>
        </form>
        <button class="text-button" data-action="ask-exit">Выйти с сервера</button>
      </div>
      ${g()}
    </section>`,x=()=>{let e=o?.characters??[],t=o?.limits.maxCharacters??0,i=e.length<t,a=e.map(e=>`
      <article class="character-card">
        <div class="avatar" aria-hidden="true">${n(e.firstName.charAt(0).toUpperCase())}</div>
        <div class="character-copy">
          <h3>${n(r(e))}</h3>
          <p>ID ${e.id}</p>
        </div>
        <button class="button button--primary button--compact" data-action="select-character" data-character-id="${e.id}" ${s?`disabled`:``}>
          ${s===`select:${e.id}`?`Выбираем…`:`Играть`}
        </button>
      </article>`).join(``);return`
      <section class="identity-shell" data-view="characters">
        <div class="panel panel--wide">
          <header class="panel-header panel-header--spread">
            <div><p class="eyebrow">Аккаунт ${n(o?.account?.email??``)}</p><h1>Выберите персонажа</h1></div>
            <button class="icon-button" data-action="ask-exit" aria-label="Выйти">↗</button>
          </header>
          ${c?m():``}
          <div class="character-grid">${a||`<p class="empty-state">Персонажей пока нет. Создайте первого.</p>`}</div>
          <div class="divider"><span>${e.length} / ${t}</span></div>
          ${i?`
            <form class="create-form" data-form="character" novalidate>
              <div class="field"><label for="firstName">Имя</label><input id="firstName" name="firstName" maxlength="32" required /></div>
              <div class="field"><label for="lastName">Фамилия</label><input id="lastName" name="lastName" maxlength="32" required /></div>
              <button class="button button--secondary" type="submit" ${s?`disabled`:``}>${s===`createCharacter`?`Создаём…`:`Создать`}</button>
            </form>`:`<p class="field-note">Достигнут доступный лимит персонажей.</p>`}
        </div>
        ${g()}
      </section>`},S=()=>{i.innerHTML=o?[`uninitialized`,`loading`,`authorized`,`registering`,`registration_finalizing`,`spawn_releasing`,`post_spawn_identity`,`character_selected`].includes(o.state)?p():o.state===`registration_required`?_():o.state===`email_verification_pending`||o.state===`auth_verification_required`?v():o.state===`registration_verified`?y():o.state===`profile_completion_required`?b():o.state===`character_required`?x():o.state===`error`?`<section class="identity-shell"><div class="panel panel--small text-center"><p class="eyebrow">Ошибка</p><h1>Профиль недоступен</h1>${m()}<button class="button button--secondary" data-action="refresh">Повторить</button></div></section>`:``:s===`refresh`?p():c?h():``,i.hidden=i.innerHTML.length===0},C=async(e,t)=>{if(s){c=`GC-IDENTITY-CLIENT-REQUEST-PENDING`,S();return}s=e,c=null,S();try{let n=await a.invoke(e.split(`:`)[0]??e,t);n.ok||(s=null,c=n.code??`GC-IDENTITY-REQUEST-REJECTED`,S())}catch{s=null,c=`GC-IDENTITY-NUI-TRANSPORT`,S()}},w=e=>{let t=e.target;if(!(t instanceof HTMLFormElement))return;e.preventDefault();let n=new FormData(t);t.dataset.form===`registration`?C(`sendRegistrationCode`,{fullName:String(n.get(`fullName`)??``).trim(),email:String(n.get(`email`)??``).trim()}):t.dataset.form===`verification`?C(`verifyEmail`,{code:String(n.get(`code`)??``).trim()}):t.dataset.form===`profile`?C(`completeProfile`,{fullName:String(n.get(`fullName`)??``).trim()}):t.dataset.form===`character`&&C(`createCharacter`,{firstName:String(n.get(`firstName`)??``).trim(),lastName:String(n.get(`lastName`)??``).trim()})},T=e=>{let t=e.target instanceof Element?e.target.closest(`[data-action]`):null;if(!t)return;let n=t.dataset.action;if(n===`select-character`){let e=Number(t.dataset.characterId);C(`selectCharacter:${e}`,{characterId:e})}else n===`ask-exit`?(l=!0,S()):n===`cancel-exit`?(l=!1,S()):n===`confirm-exit`?C(`exit`,{}):n===`dismiss-error`?(c=null,S()):n===`refresh`?C(`refresh`,{}):n===`resend-verification`?C(`resendVerification`,{}):n===`change-registration-email`?C(`changeRegistrationEmail`,{}):n===`finalize-registration`&&C(`finalizeRegistration`,{})},E=e=>{e.key===`Escape`&&o?.state!==`ready`&&(l=!l,S())};i.addEventListener(`submit`,w),i.addEventListener(`click`,T),document.addEventListener(`keydown`,E),S();let D=window.setInterval(()=>{let e=o?.verification;if(!e)return;let t=i.querySelector(`[data-expires-timer]`);t&&(t.textContent=String(f(e.expiresIn)));let n=i.querySelector(`[data-resend-timer]`),r=i.querySelector(`[data-resend-button]`),a=f(e.resendIn);n&&(n.textContent=String(a)),r&&a===0&&!s&&(r.disabled=!1,r.textContent=d(`Отправить новый код`,`Send a new code`))},1e3);return{receive(e){e.type===`snapshot`?(o=e.payload,u=Date.now(),s=null,c=null,l=!1):e.type===`rejected`?(s=null,c=e.payload.code):e.type===`lifecycleError`?(o=null,s=null,c=e.payload.code):e.type===`reset`&&(o=null,s=null,c=null,l=!1),S()},destroy(){window.clearInterval(D),i.removeEventListener(`submit`,w),i.removeEventListener(`click`,T),document.removeEventListener(`keydown`,E)}}}function a(){return window.GetParentResourceName?.()??`gc_identity`}var o={async invoke(e,t){if(typeof window.GetParentResourceName!=`function`)return{ok:!0};let n=await fetch(`https://${a()}/${e}`,{method:`POST`,headers:{"Content-Type":`application/json; charset=UTF-8`},body:JSON.stringify(t)});return n.ok?await n.json():{ok:!1,code:`GC-IDENTITY-NUI-TRANSPORT`}}},s=document.querySelector(`#app`);if(!s)throw Error(`gc_identity NUI root is missing`);var c=i(s,o);window.addEventListener(`message`,e=>{(e.data?.type===`snapshot`||e.data?.type===`rejected`||e.data?.type===`lifecycleError`||e.data?.type===`reset`)&&c.receive(e.data)}),o.invoke(`ready`,{}).then(e=>{e.ok||c.receive({type:`lifecycleError`,payload:{code:e.code??`GC-IDENTITY-NUI-TRANSPORT`}})}).catch(()=>{c.receive({type:`lifecycleError`,payload:{code:`GC-IDENTITY-NUI-TRANSPORT`}})});