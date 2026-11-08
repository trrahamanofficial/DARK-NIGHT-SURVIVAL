import { createClient } from "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm";

const $ = (id) => document.getElementById(id);
let supabase = null;
let currentUser = null;
let profileRole = null;

function status(id, message, bad = false) {
  const node = $(id); node.textContent = message; node.style.color = bad ? "#ff9cae" : "#9edfc0";
}
function show(id, yes) { $(id).classList.toggle("hidden", !yes); }
function validProjectUrl(value) {
  try { const u = new URL(value); return u.protocol === "https:" && u.hostname.endsWith(".supabase.co"); }
  catch { return false; }
}
function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, ch => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[ch]));
}
function setSignedIn(value) {
  show("login-panel", value && !currentUser);
  show("app-panel", value && !!currentUser && profileRole === "admin");
  $("session-badge").textContent = value && currentUser && profileRole === "admin" ? "ADMIN VERIFIED" : "SIGNED OUT";
}
async function verifyAdmin(user) {
  const { data, error } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (error) throw new Error("Could not verify admin role. Apply the supplied SQL and check profiles RLS.");
  if (!data || data.role !== "admin") throw new Error("Access denied: this account does not have the admin role.");
  profileRole = data.role;
  currentUser = user;
  $("admin-email").textContent = user.email || "Administrator";
  setSignedIn(true);
  await Promise.all([loadSettings(), loadAudit()]);
}
async function connect() {
  const url = $("project-url").value.trim();
  const key = $("anon-key").value.trim();
  if (!validProjectUrl(url) || !key) return status("config-status", "Enter a valid HTTPS Supabase URL and public anon key.", true);
  supabase = createClient(url, key, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } });
  status("config-status", "Connected to Supabase. Sign in with your admin account.");
  show("login-panel", true);
  show("app-panel", false);
  try {
    const { data } = await supabase.auth.getSession();
    if (data.session?.user) await verifyAdmin(data.session.user);
  } catch (e) {
    await supabase.auth.signOut();
    currentUser = null; profileRole = null;
    status("login-status", e.message, true);
    setSignedIn(true);
  }
}
async function signIn() {
  if (!supabase) return status("login-status", "Connect the Supabase project first.", true);
  const email = $("email").value.trim(), password = $("password").value;
  if (!email || !password) return status("login-status", "Enter email and password.", true);
  $("login").disabled = true;
  try {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    await verifyAdmin(data.user);
    status("login-status", "Admin access verified.");
  } catch (e) {
    currentUser = null; profileRole = null;
    await supabase.auth.signOut();
    setSignedIn(true);
    status("login-status", e.message || "Sign-in failed.", true);
  } finally { $("login").disabled = false; }
}
async function signOut() {
  if (supabase) await supabase.auth.signOut();
  currentUser = null; profileRole = null; setSignedIn(true);
}
async function loadSettings() {
  const { data, error } = await supabase.from("game_admin_settings").select("key,value,updated_at").order("key");
  if (error) throw error;
  if (!data.length) { $("settings-list").innerHTML = '<p class="muted">No settings saved yet.</p>'; return; }
  $("settings-list").innerHTML = '<table><thead><tr><th>Key</th><th>JSON value</th><th>Updated</th><th>Action</th></tr></thead><tbody>' +
    data.map(row => '<tr><td>'+escapeHtml(row.key)+'</td><td><pre>'+escapeHtml(JSON.stringify(row.value,null,2))+'</pre></td><td>'+escapeHtml(new Date(row.updated_at).toLocaleString())+'</td><td><div class="row-actions"><button data-edit="'+escapeHtml(row.key)+'">Edit</button><button class="danger" data-delete="'+escapeHtml(row.key)+'">Delete</button></div></td></tr>').join('') +
    '</tbody></table>';
  $("settings-list").querySelectorAll("[data-edit]").forEach(btn => btn.addEventListener("click", () => {
    const row = data.find(x => x.key === btn.dataset.edit); $("setting-key").value = row.key; $("setting-value").value = JSON.stringify(row.value,null,2);
  }));
  $("settings-list").querySelectorAll("[data-delete]").forEach(btn => btn.addEventListener("click", async () => {
    if (!confirm("Delete setting "+btn.dataset.delete+"?")) return;
    try { const key=btn.dataset.delete; const {error}=await supabase.from("game_admin_settings").delete().eq("key",key); if(error)throw error; await audit("setting.delete",key); await loadSettings(); status("settings-status","Setting deleted."); }
    catch(e){status("settings-status",e.message,true);}
  }));
}
async function audit(action, target) {
  const { error } = await supabase.from("admin_audit_logs").insert({ actor_id: currentUser.id, action, target });
  if (error) throw error;
}
async function saveSetting() {
  if (!currentUser || profileRole !== "admin") return;
  const key=$("setting-key").value.trim(), raw=$("setting-value").value.trim();
  if (!/^[a-zA-Z0-9_.-]{2,80}$/.test(key)) return status("settings-status","Use a 2–80 character key: letters, numbers, dot, dash or underscore.",true);
  let value; try { value=JSON.parse(raw); } catch { return status("settings-status","Value must be valid JSON.",true); }
  $("save-setting").disabled=true;
  try {
    const {error}=await supabase.from("game_admin_settings").upsert({key,value,updated_by:currentUser.id,updated_at:new Date().toISOString()},{onConflict:"key"});
    if(error)throw error;
    await audit("setting.upsert",key);
    $("setting-key").value=""; $("setting-value").value="";
    await Promise.all([loadSettings(),loadAudit()]);
    status("settings-status","Setting saved securely.");
  } catch(e){status("settings-status",e.message,true);}
  finally{$("save-setting").disabled=false;}
}
async function loadAudit() {
  const {data,error}=await supabase.from("admin_audit_logs").select("action,target,actor_id,created_at").order("created_at",{ascending:false}).limit(30);
  if(error)throw error;
  $("audit-list").innerHTML = data.length ? '<table><thead><tr><th>Time</th><th>Action</th><th>Target</th><th>Actor</th></tr></thead><tbody>'+data.map(x=>'<tr><td>'+escapeHtml(new Date(x.created_at).toLocaleString())+'</td><td>'+escapeHtml(x.action)+'</td><td>'+escapeHtml(x.target||"—")+'</td><td><code>'+escapeHtml(x.actor_id)+'</code></td></tr>').join("")+'</tbody></table>' : '<p class="muted">No audit entries yet.</p>';
}
$("connect").addEventListener("click",connect);
$("login").addEventListener("click",signIn);
$("logout").addEventListener("click",signOut);
$("save-setting").addEventListener("click",saveSetting);
$("refresh-settings").addEventListener("click",()=>loadSettings().then(()=>status("settings-status","Settings refreshed.")).catch(e=>status("settings-status",e.message,true)));
$("refresh-audit").addEventListener("click",()=>loadAudit().catch(e=>alert(e.message)));
show("login-panel",false); show("app-panel",false);
