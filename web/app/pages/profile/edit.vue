<template>
  <div class="edit-page">
    <h1 class="serif">{{ t('profile.editTitle') }}</h1>
    <form class="card edit-form" @submit.prevent="onSubmit">
      <div class="field">
        <label for="name">{{ t('common.fields.name') }}</label>
        <input id="name" v-model="name" type="text" required />
      </div>
      <div class="field">
        <label for="bio">{{ t('profile.bioLabel') }}</label>
        <textarea id="bio" v-model="bio" rows="4" maxlength="200" />
      </div>
      <div class="field">
        <label>{{ t('profile.avatarLabel') }}</label>
        <AvatarPicker v-model="avatarUrl" />
      </div>
      <!--
      <div class="field">
        <label>Avatar</label>
        <div
          class="avatar-dropzone"
          :class="{ 'is-dragover': dragOver }"
          @dragover.prevent="dragOver = true"
          @dragleave.prevent="dragOver = false"
          @drop.prevent="onDrop"
          @click="fileInput?.click()"
        >
          <input
            ref="fileInput"
            type="file"
            accept="image/png,image/jpeg,image/webp"
            class="visually-hidden"
            @change="onFileSelected"
          />
          <span>📷 Drop an image here, or click to upload</span>
        </div>
      </div>
      -->
      <p v-if="error" class="form-error">{{ error }}</p>
      <button class="btn-primary" type="submit" :disabled="saving">
        {{ saving ? t('profile.saving') : t('profile.saveChanges') }}
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const auth = useAuthStore()
const name = ref(auth.user?.name ?? '')
const bio = ref(auth.user?.bio ?? '')
const avatarUrl = ref(auth.user?.avatar_url ?? null)
const saving = ref(false)
const error = ref('')
const dragOver = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)
const router = useRouter()
const { t } = useI18n()

async function onSubmit() {
  saving.value = true
  error.value = ''
  try {
    await auth.updateProfile({ name: name.value, bio: bio.value, avatar_url: avatarUrl.value })
    router.push('/profile')
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  } finally {
    saving.value = false
  }
}

async function onFileSelected(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (file) await uploadAvatar(file)
}

async function onDrop(event: DragEvent) {
  dragOver.value = false
  const file = event.dataTransfer?.files?.[0]
  if (file) await uploadAvatar(file)
}

async function uploadAvatar(file: File) {
  error.value = ''
  try {
    await auth.uploadAvatar(file)
  } catch (err) {
    error.value = extractErrorMessage(err, t)
  }
}
</script>

<style scoped>
.edit-page {
  max-width: 480px;
  margin: 0 auto;
  padding: 48px 24px;
}

.edit-form {
  padding: 24px;
  margin-top: 24px;
}

.avatar-dropzone {
  border: 2px dashed var(--color-border);
  border-radius: 10px;
  padding: 24px;
  text-align: center;
  cursor: pointer;
  color: var(--color-text-secondary);
}

.avatar-dropzone.is-dragover {
  border-color: var(--color-accent-secondary);
  border-style: solid;
}
</style>
