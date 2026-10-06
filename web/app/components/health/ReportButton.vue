<template>
  <CommunityHealthGate :available="reports.communityHealthAvailable">
    <button
      type="button"
      class="report-button"
      :aria-label="t('reports.ariaLabel')"
      @click.stop.prevent="open"
    >
      <span class="report-icon">🚩</span>
    </button>
  </CommunityHealthGate>

  <Teleport to="body">
    <div v-if="isOpen" class="report-overlay" @click.self="close">
      <div class="report-modal card" role="dialog" aria-modal="true">
        <h3 class="serif report-title">{{ t('reports.title') }}</h3>

        <template v-if="submitted">
          <p class="form-success">{{ t('reports.submitted') }}</p>
          <button type="button" class="btn-primary" @click="close">{{ t('reports.close') }}</button>
        </template>

        <template v-else>
          <div class="field">
            <label for="report-reason">{{ t('reports.reasonLabel') }}</label>
            <select id="report-reason" v-model="selectedReason">
              <option value="" disabled>{{ t('reports.reasonPlaceholder') }}</option>
              <option v-for="reason in reports.reasons" :key="reason.code" :value="reason.code">
                {{ reasonLabel(reason) }}
              </option>
            </select>
          </div>

          <div class="field">
            <label for="report-description">{{ t('reports.descriptionLabel') }}</label>
            <textarea
              id="report-description"
              v-model="description"
              rows="3"
              :placeholder="t('reports.descriptionPlaceholder')"
            />
          </div>

          <p v-if="error" class="form-error">{{ error }}</p>

          <div class="report-actions">
            <button type="button" class="report-cancel" @click="close">{{ t('reports.cancel') }}</button>
            <button
              type="button"
              class="btn-primary report-submit"
              :disabled="pending || !selectedReason"
              @click="submit"
            >
              {{ pending ? t('reports.submitting') : t('reports.submit') }}
            </button>
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import type { ReportReason } from '~/stores/health/reports'

const props = defineProps<{ resourceType: 'post' | 'comment'; resourceId: string }>()
const { t, te } = useI18n()
const reports = useReportsStore()

// Rule names are free text entered via `mix community_health.add_rule` on
// the Community Health side — CH has no concept of locales. For the known
// rule-code vocabulary (decoupled_healthy_system.md §8) we show a properly
// translated label; any other/custom code falls back to CH's raw name.
function reasonLabel(reason: ReportReason): string {
  const key = `reports.reasons.${reason.code}`
  return te(key) ? t(key) : reason.name
}

const isOpen = ref(false)
const selectedReason = ref('')
const description = ref('')
const pending = ref(false)
const submitted = ref(false)
const error = ref('')

onMounted(() => {
  reports.ensureReasonsLoaded()
})

function open() {
  isOpen.value = true
  submitted.value = false
  error.value = ''
}

function close() {
  isOpen.value = false
  selectedReason.value = ''
  description.value = ''
}

async function submit() {
  if (!selectedReason.value || pending.value) return
  pending.value = true
  error.value = ''

  try {
    await reports.submitReport({
      resourceType: props.resourceType,
      resourceId: props.resourceId,
      reason: selectedReason.value,
      description: description.value || undefined,
    })
    submitted.value = true
  } catch {
    error.value = t('reports.error')
  } finally {
    pending.value = false
  }
}
</script>

<style scoped>
.report-button {
  display: inline-flex;
  align-items: center;
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  font-family: var(--font-sans);
}

.report-icon {
  font-size: 1rem;
  line-height: 1;
  color: var(--color-text-secondary);
  opacity: 0.7;
  transition: opacity 0.15s ease;
}

.report-button:hover .report-icon {
  opacity: 1;
}

.report-overlay {
  position: fixed;
  inset: 0;
  background: rgba(34, 37, 43, 0.45);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  z-index: 100;
}

.report-modal {
  width: 100%;
  max-width: 420px;
  padding: 28px;
}

.report-title {
  margin: 0 0 16px;
}

.report-modal select,
.report-modal textarea {
  width: 100%;
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 10px 14px;
  font-family: var(--font-sans);
  font-size: 1rem;
  background: var(--color-surface);
  color: var(--color-ink);
}

.report-modal select:focus,
.report-modal textarea:focus {
  outline: none;
  border-color: var(--color-accent-secondary);
}

.report-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 8px;
}

.report-cancel {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  font-family: var(--font-sans);
  font-size: 0.95rem;
  cursor: pointer;
}

.report-submit {
  width: auto;
  padding: 10px 20px;
}
</style>
