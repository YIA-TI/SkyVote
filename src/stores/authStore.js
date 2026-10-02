import { defineStore } from "pinia";
import { supabase } from "../lib/supabaseClient";
import { useSurveyStore } from "./surveyStore";

export const useAuthStore = defineStore("auth", {
  state: () => ({
    user: null,
    profile: null,
    ready: false,
  }),

  getters: {
    isAdmin: (state) => state.profile?.role === "admin",
  },

  actions: {
    async fetchProfile() {
      if (!this.user) {
        this.profile = null;
        return;
      }
      const { data } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", this.user.id)
        .maybeSingle();
      this.profile = data ?? null;
    },

    async restoreSession() {
      const { data } = await supabase.auth.getSession();
      this.user = data.session?.user ?? null;
      await this.fetchProfile();
      this.ready = true;

      supabase.auth.onAuthStateChange(async (_event, session) => {
        this.user = session?.user ?? null;
        await this.fetchProfile();
      });
    },

    async signIn(email, password) {
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      this.user = data.user;
      await this.fetchProfile();
      if (!this.isAdmin) {
        await this.signOut();
        throw new Error("Akun ini tidak memiliki akses admin.");
      }
    },

    async signOut() {
      const surveyStore = useSurveyStore();
      surveyStore.cleanupRealtimeSubscriptions();
      await supabase.auth.signOut();
      this.user = null;
      this.profile = null;
    },
  },
});
